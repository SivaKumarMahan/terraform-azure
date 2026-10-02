variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources. (Resources use the resource group location.)"
  type        = string
  default     = "Central India"
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
}

variable "subnet_name" {
  description = "The name of the Subnet."
  type        = string
}

variable "vm_name" {
  description = "The name of the Virtual Machine."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Source CIDR allowed to reach the VM on port 22, for example \"203.0.113.10/32\". Do not use \"*\"."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content for the VM admin user, for example the output of: cat ~/.ssh/id_rsa.pub"
  type        = string
}
