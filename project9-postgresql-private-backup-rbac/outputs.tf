output "resource_group_name" {
  description = "Resource group that holds everything."
  value       = azurerm_resource_group.this.name
}

output "postgres_server_name" {
  description = "PostgreSQL Flexible Server name."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "postgres_fqdn" {
  description = "Server FQDN. It resolves to a private IP only inside the linked VNet."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "postgres_private_dns_zone" {
  description = "Private DNS zone used by the server."
  value       = azurerm_private_dns_zone.postgres.name
}

output "database_name" {
  description = "Application database."
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "key_vault_name" {
  description = "Key Vault that holds the admin password."
  value       = azurerm_key_vault.this.name
}

output "admin_password_secret_name" {
  description = "Secret name of the break-glass admin password."
  value       = azurerm_key_vault_secret.postgres_admin_password.name
}

output "psql_entra_command" {
  description = "Connect with Entra ID from the test VM (run az login there first)."
  value       = "PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv) psql \"host=${azurerm_postgresql_flexible_server.this.fqdn} port=5432 dbname=${var.database_name} user=${var.entra_admin_principal_name} sslmode=require\""
}

output "test_vm_name" {
  description = "Test VM protected by Azure Backup."
  value       = azurerm_linux_virtual_machine.test.name
}

output "test_vm_private_ip" {
  description = "Private IP of the test VM."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "recovery_vault_name" {
  description = "Recovery Services Vault name."
  value       = azurerm_recovery_services_vault.this.name
}

output "vm_backup_policy_id" {
  description = "ID of the daily VM backup policy."
  value       = azurerm_backup_policy_vm.daily.id
}

output "custom_role_definition_id" {
  description = "Resource ID of the custom VM operator role."
  value       = azurerm_role_definition.vm_operator.role_definition_resource_id
}
