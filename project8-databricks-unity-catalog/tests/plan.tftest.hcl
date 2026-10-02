# Offline tests with mocked providers: no Azure or Databricks login needed.
# Run: tofu init -backend=false && tofu test

# Mocked values must look like real Azure IDs, because the azurerm provider
# still validates arguments such as role assignment scopes.
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dbx-uc-dev"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dbx-uc-dev/providers/Microsoft.Storage/storageAccounts/stucdev12345"
    }
  }
  mock_resource "azurerm_databricks_access_connector" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dbx-uc-dev/providers/Microsoft.Databricks/accessConnectors/dbac-uc-dev"
    }
  }
  mock_resource "azurerm_databricks_workspace" {
    defaults = {
      id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dbx-uc-dev/providers/Microsoft.Databricks/workspaces/dbw-uc-dev"
      workspace_id  = "1234567890123456"
      workspace_url = "adb-1234567890123456.7.azuredatabricks.net"
    }
  }
}

mock_provider "databricks" {}

variables {
  storage_account_name = "stucdev12345"
  metastore_id         = "11111111-2222-3333-4444-555555555555"
}

run "defaults_build_medallion_catalog" {
  command = apply

  assert {
    condition     = azurerm_databricks_workspace.this.sku == "premium"
    error_message = "Unity Catalog needs a premium workspace."
  }

  assert {
    condition     = azurerm_storage_account.uc.is_hns_enabled
    error_message = "Storage account must be ADLS Gen2 (hierarchical namespace)."
  }

  assert {
    condition     = length(databricks_metastore_assignment.this) == 1
    error_message = "Metastore assignment should be created by default."
  }

  assert {
    condition     = databricks_external_location.uc["landing"].url == "abfss://landing@stucdev12345.dfs.core.windows.net/"
    error_message = "Landing external location URL is wrong."
  }

  assert {
    condition     = databricks_catalog.this.storage_root == "abfss://catalog@stucdev12345.dfs.core.windows.net/dev_lakehouse"
    error_message = "Catalog storage_root must be inside the catalog external location."
  }

  assert {
    condition     = output.schemas == tolist(["dev_lakehouse.bronze", "dev_lakehouse.gold", "dev_lakehouse.silver"])
    error_message = "Expected bronze, silver and gold schemas."
  }

  assert {
    condition     = length(databricks_grants.schema["gold"].grant) == 2
    error_message = "gold should have grants for engineers and analysts."
  }

  assert {
    condition     = length(databricks_grants.schema["bronze"].grant) == 1
    error_message = "bronze should only be granted to engineers."
  }

  assert {
    condition     = output.workspace_url == "https://adb-1234567890123456.7.azuredatabricks.net"
    error_message = "workspace_url output should add https://."
  }
}

run "existing_assignment_skips_metastore_assignment" {
  command = plan

  variables {
    assign_metastore = false
  }

  assert {
    condition     = length(databricks_metastore_assignment.this) == 0
    error_message = "No metastore assignment when assign_metastore = false."
  }
}

run "rejects_bad_storage_account_name" {
  command = plan

  variables {
    storage_account_name = "Bad_Name"
  }

  expect_failures = [var.storage_account_name]
}

run "rejects_bad_metastore_id" {
  command = plan

  variables {
    metastore_id = "not-a-uuid"
  }

  expect_failures = [var.metastore_id]
}
