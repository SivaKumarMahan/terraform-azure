locals {
  # The App Gateway exposes its pools as a set; pick ours by name.
  appgw_backend_pool_id = one([
    for pool in azurerm_application_gateway.this.backend_address_pool : pool.id if pool.name == local.backend_pool
  ])

  cloud_init = templatefile("${path.module}/scripts/cloud-init.yaml.tftpl", {
    server_py = file("${path.module}/scripts/server.py")
    port      = 80
  })
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                 = "vmss-${var.prefix}"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  sku                  = var.vm_sku
  instances            = var.instance_count.default
  admin_username       = var.admin_username
  computer_name_prefix = "web"
  custom_data          = base64encode(local.cloud_init)
  tags                 = var.tags

  # Spread instances evenly over the zones.
  zones        = var.zones
  zone_balance = length(var.zones) > 1
  # Exactly the requested number of VMs, so autoscale numbers and the backend pool match.
  overprovision = false

  # Trusted launch (the Ubuntu 24.04 image is Gen2).
  secure_boot_enabled = true
  vtpm_enabled        = true

  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                         = "ipcfg"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.vmss.id
      application_gateway_backend_address_pool_ids = [local.appgw_backend_pool_id]
    }
  }

  # Managed boot diagnostics: serial log and screenshot, no storage account to manage.
  boot_diagnostics {}

  # The Application Health extension reports each instance as healthy or not.
  # Rolling upgrades and automatic repairs both read this signal.
  extension {
    name                       = "HealthExtension"
    publisher                  = "Microsoft.ManagedServices"
    type                       = "ApplicationHealthLinux"
    type_handler_version       = "2.0"
    auto_upgrade_minor_version = true
    settings = jsonencode({
      protocol    = "http"
      port        = 80
      requestPath = "/health"
    })
  }

  # Model changes (image, size, custom_data) roll out in batches of 20%.
  upgrade_mode = "Rolling"
  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT1M"
    prioritize_unhealthy_instances_enabled  = true
  }

  # Replace an instance that stays unhealthy after the grace period.
  automatic_instance_repair {
    enabled      = true
    grace_period = "PT10M"
    action       = "Replace"
  }

  scale_in {
    rule = "Default"
  }

  lifecycle {
    # Autoscale owns the instance count after the first apply.
    ignore_changes = [instances]
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.vmss,
    azurerm_subnet_nat_gateway_association.vmss,
  ]
}
