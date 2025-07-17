provider "mysql" {
  alias    = "azure"
  endpoint = "azure://${azurerm_mysql_flexible_server.main.fqdn}"
  username = local.aad_admin_username
  password = local.aad_admin_token
  tls      = true
  conn_params = {
    allowCleartextPasswords = "1"
  }
}


# # Create Azure AD user in MySQL database

resource "mysql_user" "azure_plaintext" {
  provider           = mysql.azure
  user               = "azure_plaintext"
  host               = "localhost"
  auth_plugin        = "caching_sha2_password"
  plaintext_password = "password"
}

## Added after 3.0.78 upgrade
resource "mysql_user" "azure_hex" {
  provider           = mysql.azure
  user               = "azure_hex"
  host               = "localhost"
  auth_plugin        = "caching_sha2_password"
  auth_string_hex    = "0x244124303035246C4F1E0D5D1631594F5C56701F3D327D073A724C706273307A5965516C7756576B317A5064687A715347765747746B66746A5A4F6E384C41756E6750495330"
}

# # Create Azure AD user for the managed identity
resource "mysql_user" "aad-users" {
  for_each    = { for user in local.aad_user : user.display_name => user }
  provider    = mysql.azure
  user        = substr(each.value.display_name, 0, 32) # Truncate to 32 characters
  host        = each.value.host
  auth_plugin = "aad_auth"
  aad_identity {
    type     = "user" # Managed identities are service principals
    identity = each.value.object_id
  }
  depends_on = [azurerm_mysql_flexible_server_active_directory_administrator.main]
}


resource "mysql_user" "umi_user" {
  provider    = mysql.azure
  user        = "umi-${substr(sha256(azurerm_user_assigned_identity.main.client_id), 0, 8)}"
  host        = "%"
  auth_plugin = "aad_auth"
  
  # Use the principal_id (object_id) for Azure AD authentication
  aad_identity {
    type = "service_principal"
    identity = azurerm_user_assigned_identity.main.principal_id
  }

  depends_on = [
    azurerm_mysql_flexible_server_active_directory_administrator.main
  ]
}

resource "mysql_user" "mysql_group" {
  provider    = mysql.azure
  user        = azuread_group.mysql_users.display_name
  host        = "%"
  auth_plugin = "aad_auth"
  
  # Use the principal_id (object_id) for Azure AD authentication
  aad_identity {
    type = "group"
    identity = azuread_group.mysql_users.display_name
  }
  depends_on = [
    azurerm_mysql_flexible_server_active_directory_administrator.main
  ]
}