output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "storage_account_name" {
  value = module.storage.name
}

output "key_vault_uri" {
  value = module.key_vault.uri
}

output "log_analytics_workspace_id" {
  value = module.observability.log_analytics_workspace_id
}

output "backend_url" {
  value = var.enable_backend ? module.backend[0].url : null
}

output "frontend_hostname" {
  value = var.enable_frontend ? module.frontend[0].default_host_name : null
}

output "postgres_fqdn" {
  value = var.enable_postgres ? module.postgres[0].fqdn : null
}
output "minio_endpoint" {
  description = "Adresse interne du service MinIO"
  value       = var.enable_minio ? module.minio[0].endpoint : null
}
output "discovery_endpoint" {
  description = "Adresse interne du Service Discovery Eureka"
  value       = var.enable_discovery ? module.discovery[0].url : null
}