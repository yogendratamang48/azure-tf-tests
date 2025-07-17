variable "aad_access_token" {
  type        = string
  description = "azure access token"
}
variable "aad_admin_username" {
  type        = string
  description = "Azure AD admin username for MySQL"
}

variable "admin_username" {
  type        = string
  description = "Admin username for MySQL"
}

variable "admin_password" {
  type        = string
  description = "Admin password for MySQL"
}

variable "aad_object_id" {
  type        = string
  description = "AAD object ID for the admin user"
}
