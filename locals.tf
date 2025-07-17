locals {
  resource_group       = "tf-playground"
  name                 = "tf-mysql"
  location             = "East US 2"
  aad_admin_username   = var.aad_admin_username
  aad_admin_token      = var.aad_access_token
  aad_object_id        = var.aad_object_id

  admin_username       = var.admin_username
  admin_password       = var.admin_password
  

  project     = "managed-identity-demo"
  environment = "production"

  ## aad_users
  aad_user = [
    {
      display_name = "anotheruser@ytamang48outlook.onmicrosoft.com"
      object_id    = "609779f8-d689-4f10-a1ba-ac47afdcdbef"
      host         = "%"
    },
  ]
}
