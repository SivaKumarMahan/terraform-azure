variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region. (Resources use the resource group location.)"
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Name of the existing resource group."
  type        = string
  default     = "test-rg"
}

variable "acr" {
  description = "ACR name. Globally unique, 5-50 alphanumeric characters."
  type        = string
  default     = "acraksdemo17825"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "testakscluster"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS API server."
  type        = string
  default     = "testaksdns"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_DS2_v2"
}
