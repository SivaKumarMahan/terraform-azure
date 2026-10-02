data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "stg" {
  for_each = var.storage_account_name

  name                            = each.value
  resource_group_name             = data.azurerm_resource_group.existing_rg.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
    ignore_changes        = [account_replication_type]

    # Normalise "Canada Central" / "canadacentral" before comparing.
    precondition {
      condition     = lower(replace(var.location, " ", "")) != "canadacentral"
      error_message = "Storage account creation is not allowed in Canada Central region!"
    }
  }
}
