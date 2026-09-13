output "id" { value = azurerm_container_app.this.id }
output "fqdn" { value = azurerm_container_app.this.latest_revision_fqdn }
output "url" { value = "https://${azurerm_container_app.this.latest_revision_fqdn}" }
output "identity_principal_id" { value = azurerm_user_assigned_identity.this.principal_id }
