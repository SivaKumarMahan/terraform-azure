output "vm_id" {
  description = "The ID of the virtual machine."
  value       = azurerm_linux_virtual_machine.vm.id
}

output "public_ip_address" {
  description = "The public IP address of the virtual machine."
  value       = azurerm_public_ip.vm_pip.ip_address
}