data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.environment == "dev" ? "nsg-dev-vm" : "nsg-stage-vm"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  dynamic "security_rule" {
    for_each = local.nsg_rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = var.allowed_source_address_prefix
      destination_address_prefix = "*"
      description                = security_rule.value.description
    }
  }
}
