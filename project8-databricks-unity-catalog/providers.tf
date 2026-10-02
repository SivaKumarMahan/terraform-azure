provider "azurerm" {
  features {}
  # null = read ARM_SUBSCRIPTION_ID from the environment (az login also works).
  subscription_id = var.subscription_id
}

# Workspace-level Databricks provider. It talks to the workspace created in this
# config and authenticates with Azure (az login, managed identity or OIDC).
# The workspace URL is only known after apply; the provider connects lazily, so a
# single apply works. If your setup fails here, apply the workspace first:
#   tofu apply -target=azurerm_databricks_workspace.this
provider "databricks" {
  host                        = azurerm_databricks_workspace.this.workspace_url
  azure_workspace_resource_id = azurerm_databricks_workspace.this.id
}
