output "id" {
  description = "Identifiant de la Container App MinIO"
  value       = azurerm_container_app.this.id
}

output "fqdn" {
  description = "Nom de domaine interne stable de MinIO"
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "endpoint" {
  description = "Adresse interne stable utilisée pour accéder à MinIO"
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}

output "identity_principal_id" {
  description = "Identifiant de l'identité managée de MinIO"
  value       = azurerm_user_assigned_identity.this.principal_id
}