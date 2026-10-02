output "vm_name" {
  description = "Name of the virtual machine."
  value       = azurerm_virtual_machine.vm.name
}

output "vm_private_ip" {
  description = "Private IP of the VM (no public IP is created)."
  value       = azurerm_network_interface.nic.private_ip_address
}

output "admin_username" {
  description = "VM admin user name."
  value       = var.admin_username
}

output "key_vault_name" {
  description = "Key Vault that stores the VM admin password."
  value       = azurerm_key_vault.kv.name
}

output "admin_password_secret_name" {
  description = "Key Vault secret name. Read it with: az keyvault secret show --vault-name <kv> --name <secret> --query value -o tsv"
  value       = azurerm_key_vault_secret.vm_admin_password.name
}

output "admin_password" {
  description = "VM admin password. Hidden in plan/apply output; read with: terraform output -raw admin_password"
  value       = random_password.vm_admin.result
  sensitive   = true
}
