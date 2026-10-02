output "workspace_url" {
  description = "Workspace URL to open in a browser."
  value       = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "workspace_id" {
  description = "Numeric Databricks workspace ID (used in the metastore assignment)."
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "storage_account_name" {
  description = "ADLS Gen2 account used by Unity Catalog."
  value       = azurerm_storage_account.uc.name
}

output "access_connector_id" {
  description = "Resource ID of the Access Connector."
  value       = azurerm_databricks_access_connector.uc.id
}

output "access_connector_principal_id" {
  description = "Object ID of the Access Connector managed identity."
  value       = azurerm_databricks_access_connector.uc.identity[0].principal_id
}

output "storage_credential_name" {
  description = "Unity Catalog storage credential."
  value       = databricks_storage_credential.uc.name
}

output "external_locations" {
  description = "External location name => abfss URL."
  value       = { for k, v in databricks_external_location.uc : v.name => v.url }
}

output "catalog_name" {
  description = "Catalog created by this config."
  value       = databricks_catalog.this.name
}

output "schemas" {
  description = "Full names of the schemas (catalog.schema)."
  value       = sort([for s in databricks_schema.layer : "${s.catalog_name}.${s.name}"])
}
