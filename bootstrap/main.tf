resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  compact_project = replace(lower(var.project_name), "-", "")
  common_tags = merge({
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "terraform-state"
  }, var.tags)
}

resource "azurerm_resource_group" "state" {
  name     = "rg-${var.project_name}-tfstate"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "state" {
  name                            = "st${local.compact_project}tf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = local.common_tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "current_user_state_access" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "ci_state_access" {
  count                = var.ci_principal_id == null ? 0 : 1
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.ci_principal_id
}
