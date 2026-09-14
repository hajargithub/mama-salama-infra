resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_container_app_environment_storage" "this" {
  name                         = "minio-data"
  container_app_environment_id = var.container_app_environment_id
  account_name                 = var.storage_account_name
  share_name                   = var.storage_share_name
  access_key                   = var.storage_account_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  registry {
    server   = var.registry_server
    identity = azurerm_user_assigned_identity.this.id
  }

  secret {
    name                = "minio-root-user"
    key_vault_secret_id = var.root_user_secret_id
    identity            = azurerm_user_assigned_identity.this.id
  }

  secret {
    name                = "minio-root-password"
    key_vault_secret_id = var.root_password_secret_id
    identity            = azurerm_user_assigned_identity.this.id
  }

  template {
    min_replicas = 1
    max_replicas = 1

    volume {
      name         = "minio-data"
      storage_name = azurerm_container_app_environment_storage.this.name
      storage_type = "AzureFile"
    }

    container {
      name   = "minio"
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      args = [
        "server",
        "/data",
        "--console-address",
        ":9001"
      ]

      env {
        name        = "MINIO_ROOT_USER"
        secret_name = "minio-root-user"
      }

      env {
        name        = "MINIO_ROOT_PASSWORD"
        secret_name = "minio-root-password"
      }

      volume_mounts {
        name = "minio-data"
        path = "/data"
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 9000
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.key_vault_secrets_user
  ]
}