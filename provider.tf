terraform {
  required_version = ">= 0.13"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.36.0"
    }
    mysql = {
      source = "petoju/mysql"
      version = "3.0.78"
    }
  }
}
