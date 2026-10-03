# ---------------------------------------------------------------------------
# Small test VM: the backup target, and a psql jump box inside the VNet
# ---------------------------------------------------------------------------

resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.prefix}-vm"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "test" {
  name                  = "vm-${var.prefix}-test"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm.id]
  tags                  = var.tags

  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  # psql client for testing the private connection.
  custom_data = base64encode(<<-EOT
    #cloud-config
    package_update: true
    packages:
      - postgresql-client
  EOT
  )

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  boot_diagnostics {}
}

# ---------------------------------------------------------------------------
# Recovery Services Vault + VM backup policy
# ---------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "this" {
  name                         = "rsv-${var.prefix}"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  sku                          = "Standard"
  storage_mode_type            = var.vault_storage_mode
  cross_region_restore_enabled = var.cross_region_restore_enabled
  tags                         = var.tags

  lifecycle {
    precondition {
      condition     = !var.cross_region_restore_enabled || var.vault_storage_mode == "GeoRedundant"
      error_message = "cross_region_restore_enabled needs vault_storage_mode = GeoRedundant."
    }
  }
}

# Daily backup with grandfather-father-son retention.
resource "azurerm_backup_policy_vm" "daily" {
  name                           = "bkpol-${var.prefix}-vm-daily"
  resource_group_name            = azurerm_resource_group.this.name
  recovery_vault_name            = azurerm_recovery_services_vault.this.name
  timezone                       = "UTC"
  instant_restore_retention_days = 2

  backup {
    frequency = "Daily"
    time      = var.vm_backup.time
  }

  retention_daily {
    count = var.vm_backup.daily
  }

  retention_weekly {
    count    = var.vm_backup.weekly
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.vm_backup.monthly
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  dynamic "retention_yearly" {
    for_each = var.vm_backup.yearly > 0 ? [1] : []
    content {
      count    = var.vm_backup.yearly
      weekdays = ["Sunday"]
      weeks    = ["First"]
      months   = ["January"]
    }
  }
}

resource "azurerm_backup_protected_vm" "test" {
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = azurerm_linux_virtual_machine.test.id
  backup_policy_id    = azurerm_backup_policy_vm.daily.id
}
