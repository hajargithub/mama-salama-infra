variable "enable_ai" {
  description = "Active le service IA."
  type        = bool
  default     = false
}

variable "ai_image" {
  type    = string
  default = "acrmamasalamapfey4yy6.azurecr.io/mama-salama-ai@sha256:db34562e2fc7fc7215bdfd7cf96911464bf3c52cdfb79e51f211bf63044c12ba"
}

module "ai" {
  count  = var.enable_ai ? 1 : 0
  source = "../../modules/container-app"

  name                         = "ai-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_app_environment.id

  container_name = "ai"
  image          = var.ai_image
  target_port    = 8000
  cpu            = 1
  memory         = "2Gi"
  min_replicas   = 1
  max_replicas   = 1

  registry_server  = module.acr.login_server
  registry_id      = module.acr.id
  key_vault_id     = module.key_vault.id
  external_enabled = false

  environment_variables = {
    OPENAI_MODEL         = "gpt-4o-mini"
    CHROMA_PATH          = "/app/chroma_db"
    EUREKA_SERVER        = "${module.discovery[0].url}/eureka/"
    EUREKA_INSTANCE_HOST = "ai-${var.project_name}-${var.environment}"

    # Port annoncé à Eureka ; Uvicorn écoute sur 8000 dans l'image.
    PORT = "80"
  }

  secret_environment_variables = {
    OPENAI_API_KEY = {
      secret_name         = "openai-api-key"
      key_vault_secret_id = "${module.key_vault.uri}secrets/openai-api-key"
    }
  }

  tags = local.common_tags
}

output "ai_url" {
  value = var.enable_ai ? module.ai[0].url : null
}