terraform {
  backend "azurerm" {
    resource_group_name  = "test-rg"
    storage_account_name = "tfstatestorage759"
    container_name       = "tfstate"
    key                  = "project5/terraform.tfstate"
  }
}