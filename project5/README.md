# lifecycle arguments 
- create_before_destroy, prevent_destroy, ignore_changes, and precondition

## create_before_destroy
default     = ["devstgoiusacct1", "devstgoiuascct2"]
    lifecycle {
      create_before_destroy = false
    }
init,plan,apply

later

default     = ["devstgoiusacct3", "devstgoiuascct4"]
    lifecycle {
      create_before_destroy = true
    }
init,plan,apply

Result: This ensures Terraform creates the new resource first before destroying the old one — useful when renaming or changing immutable fields.

## prevent_destroy
When you enable this flag, Terraform refuses to delete the resource, even if you remove or rename it.

lifecycle {
  prevent_destroy = true
}

init,plan

Error: Instance cannot be destroyed
│ 
│   on main.tf line 8:
│    8: resource "azurerm_storage_account" "stg" {
│ 
│ Resource azurerm_storage_account.stg["devstgoiuascct4"] has lifecycle.prevent_destroy set, but the plan calls for
│ this resource to be destroyed. To avoid this error and continue with the plan, either disable
│ lifecycle.prevent_destroy or reduce the scope of the plan using the -target option.
╵
╷
│ Error: Instance cannot be destroyed
│ 
│   on main.tf line 8:
│    8: resource "azurerm_storage_account" "stg" {
│ 
│ Resource azurerm_storage_account.stg["devstgoiusacct3"] has lifecycle.prevent_destroy set, but the plan calls for
│ this resource to be destroyed. To avoid this error and continue with the plan, either disable
│ lifecycle.prevent_destroy or reduce the scope of the plan using the -target option.

## ignore_changes
This tells Terraform to ignore certain attributes during future plan or apply runs — useful when attributes are changed manually outside Terraform.

lifecycle {
  ignore_changes = [account_tier]
}

terraform plan

Observe: Terraform will not detect or plan to revert that manual change.
This is helpful for fields like tags, timeouts, or external integrations managed by other tools.

## precondition

precondition {
condition     = lower(var.location) != "canadacentral"
error_message = "Storage account creation is not allowed in Canada Central region!"
}

variable "location" {
    default = "canadacentral"
} 

Error: Resource precondition failed
│ 
│   on main.tf line 21, in resource "azurerm_storage_account" "stg":
│   21:       condition     = lower(var.location) != "canadacentral"
│     ├────────────────
│     │ var.location is "canadacentral"
│ 
│ Storage account creation is not allowed in Canada Central region!
╵
╷
│ Error: Resource precondition failed
│ 
│   on main.tf line 21, in resource "azurerm_storage_account" "stg":
│   21:       condition     = lower(var.location) != "canadacentral"
│     ├────────────────
│     │ var.location is "canadacentral"
│ 
│ Storage account creation is not allowed in Canada Central region!