
provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}

data "azurerm_resource_group" "main" {
  name = local.resource_group
}

# Create a User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  name                = "${local.name}-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = local.location
  tags = {
    environment = local.environment
    project     = local.project
  }
}

## Create Azure Database for MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${local.name}-poc-001"
  resource_group_name    = data.azurerm_resource_group.main.name
  location               = local.location
  administrator_login    = local.admin_username
  administrator_password = local.admin_password

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  sku_name = "B_Standard_B1ms"
  storage {
    auto_grow_enabled = true
    size_gb           = 20
  }

  version = "8.0.21"

  # Enable managed identity authentication
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  tags = {
    environment = local.environment
    project     = local.project
  }
}

# Get current public IP
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# Create firewall rule to allow Azure services
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Create firewall rule for your current IP
resource "azurerm_mysql_flexible_server_firewall_rule" "client_ip" {
  name                = "MyCurrentIP"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = chomp(data.http.myip.response_body)
  end_ip_address      = chomp(data.http.myip.response_body)
}

resource "azurerm_mysql_flexible_server_active_directory_administrator" "main" {
  server_id   = azurerm_mysql_flexible_server.main.id
  identity_id = azurerm_user_assigned_identity.main.id
  login       = local.aad_admin_username
  object_id   = local.aad_object_id
  tenant_id   = data.azuread_client_config.current.tenant_id
}

# 2. Grant admin consent - CRITICAL STEP
# resource "null_resource" "grant_admin_consent" {
#   triggers = {
#     umi_client_id = azurerm_user_assigned_identity.main.client_id
#     timestamp     = timestamp()
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Granting admin consent for UMI permissions..."
      
#       # Wait for permissions to propagate
#       sleep 60
      
#       # Method 1: Direct admin consent
#       az ad app permission admin-consent --id ${azurerm_user_assigned_identity.main.client_id} || echo "Direct consent failed, trying alternative method..."
      
#       # Method 2: OAuth2 permission grant (alternative)
#       az rest --method POST \
#         --uri 'https://graph.microsoft.com/v1.0/oauth2PermissionGrants' \
#         --headers 'Content-Type=application/json' \
#         --body '{
#           "clientId": "${data.azuread_service_principal.umi_sp.object_id}",
#           "consentType": "AllPrincipals",
#           "principalId": null,
#           "resourceId": "${data.azuread_service_principal.msgraph.object_id}",
#           "scope": "User.Read.All GroupMember.Read.All Application.Read.All"
#         }' || echo "OAuth2 grant also failed - manual intervention may be required"
      
#       echo "Admin consent process completed"
#     EOT
#   }

#   depends_on = [
#     azuread_app_role_assignment.user_read_all,
#     azuread_app_role_assignment.group_member_read_all,
#     azuread_app_role_assignment.application_read_all
#   ]
# }
