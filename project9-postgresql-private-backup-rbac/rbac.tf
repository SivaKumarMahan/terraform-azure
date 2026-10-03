# Custom role: operators can see VMs, restart them, and read (not change or
# restore) backups. Nothing else. Scoped to this resource group only.
resource "azurerm_role_definition" "vm_operator" {
  name        = "${var.prefix} VM Operator (restart + backup read)"
  scope       = azurerm_resource_group.this.id
  description = "Read and restart VMs, read backup items, jobs and recovery points. No delete, no restore, no data access."

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.RecoveryServices/Vaults/read",
      "Microsoft.RecoveryServices/Vaults/backupPolicies/read",
      "Microsoft.RecoveryServices/Vaults/backupProtectedItems/read",
      "Microsoft.RecoveryServices/Vaults/backupJobs/read",
      "Microsoft.RecoveryServices/Vaults/backupFabrics/protectionContainers/protectedItems/read",
      "Microsoft.RecoveryServices/Vaults/backupFabrics/protectionContainers/protectedItems/recoveryPoints/read",
    ]
    not_actions = []
  }

  assignable_scopes = [azurerm_resource_group.this.id]
}

resource "azurerm_role_assignment" "operators" {
  scope              = azurerm_resource_group.this.id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id       = var.operators_group_object_id
  principal_type     = "Group"
  description        = "Custom VM operator role for the operators group (managed by Terraform)."
}
