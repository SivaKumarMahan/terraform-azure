variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region. Must be the region of the Unity Catalog metastore."
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Resource group to create for the workspace, storage and access connector."
  type        = string
  default     = "rg-dbx-uc-dev"
}

variable "workspace_name" {
  description = "Azure Databricks workspace name."
  type        = string
  default     = "dbw-uc-dev"
}

variable "storage_account_name" {
  description = "ADLS Gen2 account for Unity Catalog data. Globally unique, 3-24 lowercase letters and digits."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase letters and digits."
  }
}

variable "access_connector_name" {
  description = "Name of the Databricks Access Connector (its managed identity reads/writes the storage)."
  type        = string
  default     = "dbac-uc-dev"
}

variable "metastore_id" {
  description = "ID of the existing Unity Catalog metastore for this region (Account console > Catalog > Metastores)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.metastore_id))
    error_message = "metastore_id must be a UUID."
  }
}

variable "assign_metastore" {
  description = "Create the metastore assignment. Set false if the account auto-assigns new workspaces to the regional metastore."
  type        = bool
  default     = true
}

variable "catalog_name" {
  description = "Unity Catalog catalog to create."
  type        = string
  default     = "dev_lakehouse"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.catalog_name))
    error_message = "catalog_name must be lowercase letters, digits and underscores, starting with a letter."
  }
}

variable "schemas" {
  description = "Schemas (medallion layers) to create in the catalog, with a comment for each."
  type        = map(string)
  default = {
    bronze = "Raw data as ingested, append only"
    silver = "Cleaned and conformed data"
    gold   = "Business-level aggregates for reporting"
  }
}

variable "data_engineers_group" {
  description = "Account-level group that builds pipelines. Gets read/write on all schemas."
  type        = string
  default     = "data-engineers"
}

variable "data_analysts_group" {
  description = "Account-level group that reads curated data. Gets SELECT on analyst_schemas only."
  type        = string
  default     = "data-analysts"
}

variable "analyst_schemas" {
  description = "Schemas the analysts group may read."
  type        = set(string)
  default     = ["gold"]
}

variable "catalog_force_destroy" {
  description = "Allow destroy to drop the catalog even if it still has schemas/tables. Keep false outside labs."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for all Azure resources."
  type        = map(string)
  default = {
    project    = "databricks-unity-catalog"
    managed_by = "opentofu"
  }
}
