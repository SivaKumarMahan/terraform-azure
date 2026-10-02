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
  description = "Azure region. (Not used: storage accounts use the resource group location.)"
  type        = string
  default     = "Central India"
}

variable "storage_account_name" {
  description = "Set of storage account names. Each must be globally unique, 3-24 lowercase letters and digits."
  type        = set(string)
  default     = ["devstgoiuacct1", "devstgoiuacct2", "devstgoiuacct3"]

  validation {
    condition     = alltrue([for n in var.storage_account_name : can(regex("^[a-z0-9]{3,24}$", n))])
    error_message = "Storage account names must be 3-24 lowercase letters and digits."
  }
}
