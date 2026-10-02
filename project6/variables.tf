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
  description = "Azure region. (Not used: the NSG uses the resource group location.)"
  type        = string
  default     = "centralindia"
}

variable "environment" {
  description = "Environment name. \"dev\" gives nsg-dev-vm, anything else gives nsg-stage-vm."
  type        = string
  default     = "dev"
}

variable "allowed_source_address_prefix" {
  description = "Source address prefix for the inbound rules. \"*\" means the whole internet; use your IP/32 or a VNet range for real VMs."
  type        = string
  default     = "*"
}
