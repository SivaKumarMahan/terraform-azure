output "names_of_storage_accounts" {
  description = "Names of all storage accounts."
  value       = [for sa in azurerm_storage_account.stg : sa.name]
}
