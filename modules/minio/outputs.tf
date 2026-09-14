output "id" {
  description = "Identifiant de la Container App MinIO"
  value       = azurerm_container_app.this.id
}

output "fqdn" {
  description = "Nom de domaine interne de MinIO"
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "endpoint" {
  description = "Adresse interne utilisée pour accéder à MinIO"
  value       = "https://${azurerm_container_app.this.latest_revision_fqdn}"
}

output "identity_principal_id" {
  description = "Identifiant de l'identité managée de MinIO"
  value       = azurerm_user_assigned_identity.this.principal_id
}