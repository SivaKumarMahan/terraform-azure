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
  description = "Azure region for the storage account and NSG."
  type        = string
  default     = "centralindia"
}

variable "environment" {
  description = "Environment name, used for the NSG name and the envs lookup."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Free-text project name (Assignment 1)."
  type        = string
  default     = "project7 Terraform"
}

variable "default_tags" {
  type = map(string)
  default = {
    company    = "dummy"
    managed_by = "terraform"
  }
}

variable "environment_tags" {
  type = map(string)
  default = {
    environment = "dev"
    cost-center = "it"
  }
}

variable "storage_account_name" {
  description = "Raw storage account name. It is normalised in locals.tf (Assignment 3)."
  type        = string
  default     = "tfstatestorage757"
}

variable "allowed_ports_str" {
  description = "Comma-separated list of inbound TCP ports (Assignment 4)."
  type        = string
  default     = "22,80,443"

  validation {
    condition = alltrue([
      for p in split(",", var.allowed_ports_str) :
      can(regex("^\\d+$", trimspace(p))) && tonumber(trimspace(p)) >= 1 && tonumber(trimspace(p)) <= 65535
    ])
    error_message = "allowed_ports_str must be comma-separated port numbers between 1 and 65535."
  }
}

variable "allowed_source_address_prefix" {
  description = "Source address prefix for the NSG rules. \"*\" means the whole internet; restrict it for real VMs."
  type        = string
  default     = "*"
}

variable "envs" {
  type = map(object({
    redundancy    = string
    instance_size = string
  }))
  default = {
    dev = {
      instance_size = "small"
      redundancy    = "low"
    }
    prod = {
      instance_size = "large"
      redundancy    = "high"
    }
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
  validation {
    condition     = length(var.vm_size) >= 2 && length(var.vm_size) <= 20 && can(regex("standard", lower(var.vm_size)))
    error_message = "VM size must contain the word 'standard' and be between 2 and 20 characters."
  }
}

variable "backup_name" {
  type    = string
  default = "daily_backup"

  validation {
    condition     = endswith(var.backup_name, "_backup")
    error_message = "Backup name must end with '_backup'."
  }
}

variable "credential" {
  type        = string
  description = "Sensitive credential variable"
  sensitive   = true

}

variable "monthly_costs" {
  type    = list(number)
  default = [-50, 100, 75, 200]
}

variable "user_locations" {
  description = "Locations requested by users (Assignment 9). Duplicates are allowed."
  type        = list(string)
  default     = ["eastus", "westus", "eastus"]
}

variable "default_locations" {
  description = "Locations always included (Assignment 9)."
  type        = list(string)
  default     = ["centralus"]
}