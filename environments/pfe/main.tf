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

module "container_app_environment" {
  source                     = "../../modules/container-app-environment"
  name                       = "cae-${var.project_name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "backend" {
  count                        = var.enable_backend ? 1 : 0
  source                       = "../../modules/container-app"
  name                         = "ca-backend-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_app_environment.id
  container_name               = "backend"
  image                        = var.backend_image
  target_port                  = var.backend_port
  registry_server              = module.acr.login_server
  registry_id                  = module.acr.id
  environment_variables        = var.backend_env
  tags                         = local.common_tags
}

module "frontend" {
  count               = var.enable_frontend ? 1 : 0
  source              = "../../modules/static-web-app"
  name                = "swa-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "West Europe"
  tags                = local.common_tags
}
