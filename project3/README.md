Error:

azurerm_management_lock.rg_lock: Destruction complete after 2m8s
╷
│ Error: deleting Virtual Machine (Subscription: "ed79d02d-bd46-4fa8-96bb-4fcddc112959"
│ Resource Group Name: "test-rg"
│ Virtual Machine Name: "dev-vm"): performing Delete: unexpected status 409 (409 Conflict) with error: ScopeLocked: The scope '/subscriptions/subscription-id/resourceGroups/test-rg/providers/Microsoft.Compute/virtualMachines/dev-vm' cannot perform delete operation because following scope(s) are locked: '/subscriptions/subscription-id/resourceGroups/aimsplus'. Please remove the lock and try again.
│ 
│ 
╵
Releasing state lock. This may take a few moments...

Solution:
Add this block
resource "azurerm_management_lock" "rg_lock" {
  name       = "RG-Delete-Lock"
  scope      = data.azurerm_resource_group.existing_rg.id
  lock_level = "CanNotDelete"
  notes      = "This resource group is protected from deletion."

  depends_on = [
    azurerm_virtual_machine.vm,
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet,
    azurerm_network_interface.nic
  ]
}

terraform init
terraform plan
terraform destroy