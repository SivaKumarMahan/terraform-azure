# databricks_grants is authoritative: it sets the full list of grants on one
# securable and removes anything else. Grant to groups, never to single users.

locals {
  engineer_schema_privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE", "CREATE_VOLUME", "READ_VOLUME", "WRITE_VOLUME"]
  analyst_schema_privileges  = ["USE_SCHEMA", "SELECT"]
}

resource "databricks_grants" "catalog" {
  catalog = databricks_catalog.this.name

  grant {
    principal  = var.data_engineers_group
    privileges = ["USE_CATALOG", "BROWSE"]
  }

  grant {
    principal  = var.data_analysts_group
    privileges = ["USE_CATALOG", "BROWSE"]
  }
}

resource "databricks_grants" "schema" {
  for_each = databricks_schema.layer

  schema = each.value.id # "<catalog>.<schema>"

  grant {
    principal  = var.data_engineers_group
    privileges = local.engineer_schema_privileges
  }

  dynamic "grant" {
    for_each = contains(var.analyst_schemas, each.key) ? [1] : []
    content {
      principal  = var.data_analysts_group
      privileges = local.analyst_schema_privileges
    }
  }
}

# Engineers can list and read raw files in the landing zone (for Auto Loader / COPY INTO).
resource "databricks_grants" "landing" {
  external_location = databricks_external_location.uc["landing"].id

  grant {
    principal  = var.data_engineers_group
    privileges = ["READ_FILES", "CREATE_EXTERNAL_TABLE"]
  }
}
