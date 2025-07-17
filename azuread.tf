
provider "azuread" {
}
data "azuread_client_config" "current" {}
# Data source to get Microsoft Graph API
data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

# Data source to get the service principal for the User Managed Identity
data "azuread_service_principal" "umi_sp" {
  client_id = azurerm_user_assigned_identity.main.client_id
}

# Grant User.Read.All permission
resource "azuread_app_role_assignment" "user_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
  principal_object_id = data.azuread_service_principal.umi_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant Application.Read.All permission
resource "azuread_app_role_assignment" "application_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Application.Read.All"]
  principal_object_id = data.azuread_service_principal.umi_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant GroupMember.Read.All permission
resource "azuread_app_role_assignment" "group_member_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["GroupMember.Read.All"]
  principal_object_id = data.azuread_service_principal.umi_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_group" "mysql_users" {
  display_name     = "${local.name}-mysql-users"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
  description      = "Group for MySQL database users"
}