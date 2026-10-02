data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

# Storage account using normalized name
resource "azurerm_storage_account" "st" {
  name                     = local.storage_normalized
  resource_group_name      = data.azurerm_resource_group.existing_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.merged_tags

  lifecycle {
    # show create_before_destroy behavior toggled by you in experiments
    create_before_destroy = false
    prevent_destroy       = false
    ignore_changes        = [account_replication_type]

    # Assignment 3: fail at plan time if normalisation leaves an invalid name
    precondition {
      condition     = length(local.storage_normalized) >= 3
      error_message = "The normalised storage account name must be at least 3 characters."
    }
  }
}

locals {
  nsg_rules_map = {
    for idx, p in local.ports_list_clean :
    "allow_port_${p}" => {
      priority               = 100 + idx * 10
      destination_port_range = p
      description            = "Allow port ${p}"
    }
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.environment == "dev" ? "nsg-dev-vm" : "nsg-stage-vm"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  dynamic "security_rule" {
    for_each = local.nsg_rules_map
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