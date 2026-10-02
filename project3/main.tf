data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

# Who is running Terraform (user or service principal). Used for the Key Vault tenant and role assignment.
data "azurerm_client_config" "current" {}

resource "azurerm_management_lock" "rg_lock" {
  name       = "RG-Delete-Lock"
  scope      = data.azurerm_resource_group.existing_rg.id
  lock_level = "CanNotDelete"
  notes      = "This resource group is protected from deletion."

  # The lock is created last and destroyed first, so "terraform destroy" can remove everything else.
  depends_on = [
    azurerm_virtual_machine.vm,
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet,
    azurerm_network_interface.nic,
    azurerm_key_vault.kv,
    azurerm_key_vault_secret.vm_admin_password,
    azurerm_role_assignment.kv_secrets_officer,
  ]
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-vnet"
  address_space       = [element(var.network_config, 0)]
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = data.azurerm_resource_group.existing_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${element(var.network_config, 1)}/${element(var.network_config, 2)}"]
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.environment}-nic"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ---------------------------------------------------------------------------
# VM admin password: generated, never written in code, stored in Key Vault.
# ---------------------------------------------------------------------------

# Azure needs 3 of 4 character classes; min_* makes sure we always meet that.
resource "random_password" "vm_admin" {
  length           = 24
  special          = true
  override_special = "!#%*()-_=+[]{}:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# Key Vault names are global and 3-24 characters, so add a short random suffix.
resource "random_string" "kv_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_key_vault" "kv" {
  name                       = "${var.environment}-kv-${random_string.kv_suffix.result}"
  location                   = data.azurerm_resource_group.existing_rg.location
  resource_group_name        = data.azurerm_resource_group.existing_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  # Demo setting so "destroy" can purge the vault. Use true in production.
  purge_protection_enabled = false

  tags = var.resource_tags
}

# Let the identity that runs Terraform write secrets (RBAC model, no access policies).
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "${var.environment}-vm-admin-password"
  value        = random_password.vm_admin.result
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "password"

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.environment}-vm"
  location              = data.azurerm_resource_group.existing_rg.location
  resource_group_name   = data.azurerm_resource_group.existing_rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.vm_config.size

  delete_os_disk_on_termination = var.is_delete

  storage_os_disk {
    name              = "${var.environment}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.storage_disk
  }

  storage_image_reference {
    publisher = var.vm_config.publisher
    offer     = var.vm_config.offer
    sku       = var.vm_config.sku
    version   = var.vm_config.version
  }

  os_profile {
    computer_name  = "${var.environment}-vm"
    admin_username = var.admin_username
    admin_password = random_password.vm_admin.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = var.resource_tags["environment"]
    managed_by  = var.resource_tags["managed_by"]
    department  = var.resource_tags["department"]
  }

  lifecycle {
    precondition {
      condition     = contains(var.allowed_vm_sizes, var.vm_config.size)
      error_message = "vm_config.size must be one of allowed_vm_sizes."
    }
    precondition {
      condition     = contains([for l in var.allowed_locations : lower(replace(l, " ", ""))], lower(replace(data.azurerm_resource_group.existing_rg.location, " ", "")))
      error_message = "The resource group location is not in allowed_locations."
    }
  }
}
