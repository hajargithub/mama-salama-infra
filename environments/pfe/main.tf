resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "random_password" "postgres" {
  count            = var.enable_postgres ? 1 : 0
  length           = 24
  special          = true
  override_special = "!#%&*-_"
}
resource "random_bytes" "backend_jwt_secret" {
  count  = var.enable_backend ? 1 : 0
  length = 64
}

resource "random_password" "backend_admin_password" {
  count            = var.enable_backend ? 1 : 0
  length           = 24
  special          = true
  override_special = "!#%&*-_"
}

resource "azurerm_key_vault_secret" "backend_jwt_secret" {
  count        = var.enable_backend ? 1 : 0
  name         = "backend-jwt-secret"
  value        = random_bytes.backend_jwt_secret[0].base64
  key_vault_id = module.key_vault.id
}

resource "azurerm_key_vault_secret" "backend_admin_password" {
  count        = var.enable_backend ? 1 : 0
  name         = "backend-admin-password"
  value        = random_password.backend_admin_password[0].result
  key_vault_id = module.key_vault.id
}

locals {
  compact_project = replace(lower(var.project_name), "-", "")
  suffix          = random_string.suffix.result
  common_tags = merge({
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }, var.tags)
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

module "observability" {
  source              = "../../modules/observability"
  name                = "obs-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

module "acr" {
  source              = "../../modules/acr"
  name                = "acr${local.compact_project}${var.environment}${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

module "storage" {
  source              = "../../modules/storage"
  name                = "st${local.compact_project}${var.environment}${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

module "key_vault" {
  source              = "../../modules/key-vault"
  name                = "kv-${local.compact_project}-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  administrator_id    = data.azurerm_client_config.current.object_id
  tags                = local.common_tags
}

resource "azurerm_key_vault_secret" "postgres_password" {
  count        = var.enable_postgres ? 1 : 0
  name         = "postgres-admin-password"
  value        = random_password.postgres[0].result
  key_vault_id = module.key_vault.id

  depends_on = [module.key_vault]
}

module "postgres" {
  count                  = var.enable_postgres ? 1 : 0
  source                 = "../../modules/postgres"
  name                   = "psql-${var.project_name}-${var.environment}-${local.suffix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  database_name          = var.postgres_database_name
  administrator_login    = var.postgres_admin_username
  administrator_password = random_password.postgres[0].result
  sku_name               = var.postgres_sku_name
  tags                   = local.common_tags
}
resource "random_string" "minio_root_user_suffix" {
  count   = var.enable_minio ? 1 : 0
  length  = 8
  upper   = false
  special = false
}

resource "random_password" "minio_root_password" {
  count            = var.enable_minio ? 1 : 0
  length           = 32
  special          = true
  override_special = "!#%&*-_"
}

resource "azurerm_key_vault_secret" "minio_root_user" {
  count        = var.enable_minio ? 1 : 0
  name         = "minio-root-user"
  value        = "minio${random_string.minio_root_user_suffix[0].result}"
  key_vault_id = module.key_vault.id
}

resource "azurerm_key_vault_secret" "minio_root_password" {
  count        = var.enable_minio ? 1 : 0
  name         = "minio-root-password"
  value        = random_password.minio_root_password[0].result
  key_vault_id = module.key_vault.id
}

module "container_app_environment" {
  source                     = "../../modules/container-app-environment"
  name                       = "cae-${var.project_name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "backend" {
  count  = var.enable_backend ? 1 : 0
  source = "../../modules/container-app"

  name                         = "ca-backend-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_app_environment.id

  container_name = "backend"
  image          = var.backend_image
  target_port    = var.backend_port
  cpu            = 0.5
  memory         = "1Gi"
  min_replicas   = 1
  max_replicas   = 1

  registry_server  = module.acr.login_server
  registry_id      = module.acr.id
  key_vault_id     = module.key_vault.id
  external_enabled = false

  environment_variables = merge(var.backend_env, {
    SERVER_PORT                          = tostring(var.backend_port)
    SPRING_DATASOURCE_URL                = "jdbc:postgresql://${module.postgres[0].fqdn}:5432/${var.postgres_database_name}?sslmode=require"
    DB_USERNAME                          = var.postgres_admin_username
    EUREKA_CLIENT_SERVICEURL_DEFAULTZONE = "${module.discovery[0].url}/eureka/"

    EUREKA_INSTANCE_PREFER_IP_ADDRESS       = "false"
    EUREKA_INSTANCE_HOSTNAME                = "ca-backend-${var.project_name}-${var.environment}"
    EUREKA_INSTANCE_NON_SECURE_PORT         = "80"
    EUREKA_INSTANCE_NON_SECURE_PORT_ENABLED = "true"
    EUREKA_INSTANCE_SECURE_PORT_ENABLED     = "false"

    MAIL_HOST      = "smtp.gmail.com"
    MAIL_PORT      = "587"
    MINIO_ENDPOINT = module.minio[0].endpoint
    MINIO_BUCKET   = var.minio_bucket_name
    FRONTEND_URL   = var.frontend_url

    TWILIO_ACCOUNT_SID  = "AC00000000000000000000000000000000"
    TWILIO_AUTH_TOKEN   = "sms-disabled-for-pfe"
    TWILIO_PHONE_NUMBER = "+10000000000"
  })

  secret_environment_variables = {
    DB_PASSWORD = {
      secret_name         = "db-password"
      key_vault_secret_id = azurerm_key_vault_secret.postgres_password[0].versionless_id
    }

    MAIL_USERNAME = {
      secret_name         = "mail-username"
      key_vault_secret_id = "${module.key_vault.uri}secrets/mail-username"
    }

    MAIL_PASSWORD = {
      secret_name         = "mail-password"
      key_vault_secret_id = "${module.key_vault.uri}secrets/mail-password"
    }

    JWT_SECRET = {
      secret_name         = "jwt-secret"
      key_vault_secret_id = azurerm_key_vault_secret.backend_jwt_secret[0].versionless_id
    }

    ADMIN_EMAIL = {
      secret_name         = "admin-email"
      key_vault_secret_id = "${module.key_vault.uri}secrets/mail-username"
    }

    ADMIN_PASSWORD = {
      secret_name         = "admin-password"
      key_vault_secret_id = azurerm_key_vault_secret.backend_admin_password[0].versionless_id
    }

    MINIO_ACCESS_KEY = {
      secret_name         = "minio-access-key"
      key_vault_secret_id = azurerm_key_vault_secret.minio_root_user[0].versionless_id
    }

    MINIO_SECRET_KEY = {
      secret_name         = "minio-secret-key"
      key_vault_secret_id = azurerm_key_vault_secret.minio_root_password[0].versionless_id
    }
  }

  tags = local.common_tags
}

module "frontend" {
  count               = var.enable_frontend ? 1 : 0
  source              = "../../modules/static-web-app"
  name                = "swa-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "West Europe"
  tags                = local.common_tags
}
module "minio" {
  count  = var.enable_minio ? 1 : 0
  source = "../../modules/minio"

  name                         = "minio-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_app_environment.id

  image           = var.minio_image
  registry_server = module.acr.login_server
  registry_id     = module.acr.id

  storage_account_name       = module.storage.name
  storage_account_access_key = module.storage.primary_access_key
  storage_share_name         = module.storage.minio_share_name

  key_vault_id            = module.key_vault.id
  root_user_secret_id     = azurerm_key_vault_secret.minio_root_user[0].versionless_id
  root_password_secret_id = azurerm_key_vault_secret.minio_root_password[0].versionless_id

  tags = local.common_tags
}
module "discovery" {
  count  = var.enable_discovery ? 1 : 0
  source = "../../modules/container-app"

  name                         = "discovery-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_app_environment.id

  container_name = "service-discovery"
  image          = var.discovery_image
  target_port    = 8761
  cpu            = 0.5
  memory         = "1Gi"
  min_replicas   = 1
  max_replicas   = 1

  registry_server  = module.acr.login_server
  registry_id      = module.acr.id
  external_enabled = false

  environment_variables = {
    SERVER_PORT                        = "8761"
    EUREKA_CLIENT_REGISTER_WITH_EUREKA = "false"
    EUREKA_CLIENT_FETCH_REGISTRY       = "false"
  }

  tags = local.common_tags
}
module "gateway" {
  count  = var.enable_gateway ? 1 : 0
  source = "../../modules/container-app"

  name                         = "gateway-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_app_environment.id

  container_name = "service-gateway"
  image          = var.gateway_image
  target_port    = var.gateway_port
  cpu            = 0.5
  memory         = "1Gi"
  min_replicas   = 1
  max_replicas   = 1

  registry_server  = module.acr.login_server
  registry_id      = module.acr.id
  external_enabled = true

  environment_variables = {
    SERVER_PORT                          = tostring(var.gateway_port)
    EUREKA_CLIENT_SERVICEURL_DEFAULTZONE = "${module.discovery[0].url}/eureka/"
    EUREKA_CLIENT_REGISTER_WITH_EUREKA   = "false"
    EUREKA_CLIENT_FETCH_REGISTRY         = "true"

    SPRING_APPLICATION_JSON = jsonencode({
      spring = {
        cloud = {
          gateway = {
            mvc = {
              routes = [
                {
                  id         = "mama-salama-core"
                  uri        = "lb://mama-salama-core"
                  predicates = ["Path=/api/core/**"]
                  filters    = ["StripPrefix=2"]
                },
                {
                  id  = "mama-salama-ai"
                  uri = "lb://mama-salama-ai"
                  predicates = [
                    "Path=/api/ai/api/chat,/api/ai/api/voice-chat,/api/ai/api/health"
                  ]
                  filters = ["StripPrefix=2"]
                }
              ]
            }
          }
        }
      }
    })
  }

  tags = local.common_tags
}