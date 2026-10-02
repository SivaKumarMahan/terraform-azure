# The state storage account was created outside Terraform and then imported:
#   terraform import azurerm_storage_account.existing \
#     /subscriptions/<subscription-id>/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/tfstatestorage749
#
# This storage account holds the remote state of this project (see backend.tf).
# prevent_destroy stops a "terraform destroy" from deleting the state it is writing to.
resource "azurerm_storage_account" "existing" {
  name                     = "tfstatestorage749"
  resource_group_name      = "test-rg"
  location                 = "Central India"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  lifecycle {
    prevent_destroy = true
  }
}
