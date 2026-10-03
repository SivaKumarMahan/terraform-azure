data "azurerm_client_config" "current" {}

# Key Vault names are global and 3-24 characters, so add a short random suffix.
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.prefix}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.key_vault_purge_protection

  # No allowed IPs = no public access at all; reach it only through the private endpoint.
  public_network_access_enabled = length(var.key_vault_allowed_ips) > 0

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.key_vault_allowed_ips
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${var.prefix}-kv"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.prefix}-kv"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  # Creates the A record kv-...privatelink.vaultcore.azure.net -> private IP.
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
}

# The identity that runs Terraform may write secrets (RBAC model, no access policies).
resource "azurerm_role_assignment" "deployer_kv_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "${var.prefix}-pg-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = azurerm_key_vault.this.id
  content_type = "password"
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.deployer_kv_secrets,
    azurerm_private_endpoint.key_vault,
  ]
}
