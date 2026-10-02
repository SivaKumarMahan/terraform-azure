data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

module "network" {
  source              = "./modules/network"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = data.azurerm_resource_group.existing_rg.location
  vnet_name           = var.vnet_name
  subnet_name         = var.subnet_name
  allowed_ssh_cidr    = var.allowed_ssh_cidr
}

module "vm" {
  source              = "./modules/vm"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = data.azurerm_resource_group.existing_rg.location
  subnet_id           = module.network.subnet_id
  vm_name             = var.vm_name
  ssh_public_key      = var.ssh_public_key
}
