# Outputs
output "managed_identity_id" {
  value = azurerm_user_assigned_identity.main.id
}

output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.main.principal_id
}

output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.main.client_id
}

output "mysql_server_fqdn" {
  value = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_server_name" {
  value = azurerm_mysql_flexible_server.main.name
}


output "my_current_ip" {
  value       = chomp(data.http.myip.response_body)
  description = "Your current public IP address that has been added to the firewall"
}

output "user_managed_identity" {
  value = {
    id           = azurerm_user_assigned_identity.main.id
    client_id    = azurerm_user_assigned_identity.main.client_id
    principal_id = azurerm_user_assigned_identity.main.principal_id
    tenant_id    = azurerm_user_assigned_identity.main.tenant_id
  }
}