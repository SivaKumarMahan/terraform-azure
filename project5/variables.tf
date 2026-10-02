variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of the existing resource group."
  type        = string
  default     = "test-rg"
}

variable "location" {
  description = "Region for the storage accounts. Set to canadacentral to see the precondition fail."
  type        = string
  default     = "centralindia"
}

variable "storage_account_name" {
  description = "Set of storage account names. Each must be globally unique, 3-24 lowercase letters and digits."
  type        = set(string)
  default     = ["devstgoiusacct5", "devstgoiuascct6"]
}
