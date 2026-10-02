locals {
  # One container per external location.
  #   catalog: managed storage root for the catalog (tables created by UC)
  #   landing: raw files dropped by upstream systems (read with READ FILES / Auto Loader)
  containers = toset(["catalog", "landing"])

  abfss = { for c in local.containers : c => "abfss://${c}@${azurerm_storage_account.uc.name}.dfs.core.windows.net/" }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Azure: workspace, ADLS Gen2 and the Access Connector (managed identity)
# ---------------------------------------------------------------------------

resource "azurerm_databricks_workspace" "this" {
  name                        = var.workspace_name
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium" # Unity Catalog needs Premium
  managed_resource_group_name = "${var.resource_group_name}-managed"
  tags                        = var.tags
}

resource "azurerm_storage_account" "uc" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true # ADLS Gen2 (hierarchical namespace)
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "uc" {
  for_each = local.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.uc.id
  container_access_type = "private"
}

resource "azurerm_databricks_access_connector" "uc" {
  name                = var.access_connector_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# The connector identity is the only thing with data access to the account.
# Users never get storage keys; Unity Catalog grants decide who can read what.
resource "azurerm_role_assignment" "uc_blob_contributor" {
  scope                            = azurerm_storage_account.uc.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_databricks_access_connector.uc.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# ---------------------------------------------------------------------------
# Databricks: metastore assignment, credential, external locations
# ---------------------------------------------------------------------------

resource "databricks_metastore_assignment" "this" {
  count = var.assign_metastore ? 1 : 0

  workspace_id = azurerm_databricks_workspace.this.workspace_id
  metastore_id = var.metastore_id
}

resource "databricks_storage_credential" "uc" {
  name    = "${var.access_connector_name}-cred"
  comment = "Managed identity of ${var.access_connector_name}. Managed by OpenTofu."

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.uc.id
  }

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_external_location" "uc" {
  for_each = local.containers

  name            = "${var.catalog_name}_${each.key}"
  url             = local.abfss[each.key]
  credential_name = databricks_storage_credential.uc.name
  comment         = "Container ${each.key} on ${azurerm_storage_account.uc.name}. Managed by OpenTofu."

  # Databricks validates access on create, so the role assignment and the
  # container must exist first. RBAC can take a few minutes to propagate.
  depends_on = [
    azurerm_role_assignment.uc_blob_contributor,
    azurerm_storage_container.uc,
  ]
}

# ---------------------------------------------------------------------------
# Databricks: catalog and medallion schemas
# ---------------------------------------------------------------------------

resource "databricks_catalog" "this" {
  name          = var.catalog_name
  comment       = "Lakehouse catalog with medallion schemas. Managed by OpenTofu."
  storage_root  = "${local.abfss["catalog"]}${var.catalog_name}"
  force_destroy = var.catalog_force_destroy

  properties = {
    purpose = "medallion"
  }

  # storage_root must sit inside an external location.
  depends_on = [databricks_external_location.uc]
}

resource "databricks_schema" "layer" {
  for_each = var.schemas

  catalog_name = databricks_catalog.this.name
  name         = each.key
  comment      = each.value
}
