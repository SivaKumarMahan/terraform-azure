# Break-glass admin password: generated, stored in Key Vault, never in code.
resource "random_password" "postgres_admin" {
  length           = 32
  special          = true
  override_special = "!#%*()-_=+[]{}:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_postgresql_flexible_server" "this" {
  # Server names are global (they become a DNS name), so reuse the random suffix.
  name                = "psql-${var.prefix}-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  version             = var.postgres_version
  sku_name            = var.postgres_sku
  storage_mb          = var.postgres_storage_mb
  auto_grow_enabled   = true
  zone                = var.postgres_zone

  # Private access (VNet integration): no public endpoint at all.
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  administrator_login    = var.postgres_admin_login
  administrator_password = random_password.postgres_admin.result

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Sunday 02:00 UTC
  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = var.tags

  lifecycle {
    # Azure can move the server to another zone (for example after an HA failover).
    ignore_changes = [zone]
  }

  # The DNS zone must be linked before the server is created, or creation fails.
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres,
    azurerm_subnet_network_security_group_association.postgres,
  ]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = var.entra_admin_object_id
  principal_name      = var.entra_admin_principal_name
  principal_type      = var.entra_admin_principal_type
}

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = var.server_parameters

  server_id = azurerm_postgresql_flexible_server.this.id
  name      = each.key
  value     = each.value
}

# For a real database add lifecycle { prevent_destroy = true }.
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
