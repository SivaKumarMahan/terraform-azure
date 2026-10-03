variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region. It must support availability zones (for example centralindia, westeurope, eastus2)."
  type        = string
  default     = "centralindia"
}

variable "prefix" {
  description = "Short name used in every resource name, for example web-dev."
  type        = string
  default     = "web-dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,15}$", var.prefix))
    error_message = "prefix must be 3-16 characters: lowercase letters, digits and '-', starting with a letter."
  }
}

variable "resource_group_name" {
  description = "Resource group to create for this project."
  type        = string
  default     = "rg-web-dev"
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
    project     = "project8-appgw-waf-vmss-autoscale"
  }
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space of the VNet."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "vnet_address_space must be a valid IPv4 CIDR, for example 10.10.0.0/16."
  }
}

variable "appgw_subnet_prefix" {
  description = "Subnet for the Application Gateway. Only the gateway may use it. /24 is the recommended size for v2."
  type        = string
  default     = "10.10.1.0/24"

  validation {
    condition     = can(cidrhost(var.appgw_subnet_prefix, 0)) && tonumber(split("/", var.appgw_subnet_prefix)[1]) <= 26
    error_message = "appgw_subnet_prefix must be a valid CIDR of /26 or larger (v2 autoscaling needs the room)."
  }
}

variable "vmss_subnet_prefix" {
  description = "Subnet for the VM Scale Set instances."
  type        = string
  default     = "10.10.2.0/24"

  validation {
    condition     = can(cidrhost(var.vmss_subnet_prefix, 0))
    error_message = "vmss_subnet_prefix must be a valid IPv4 CIDR."
  }
}

variable "zones" {
  description = "Availability zones for the gateway, its public IP and the scale set."
  type        = list(string)
  default     = ["1", "2", "3"]

  validation {
    condition     = length(var.zones) > 0 && alltrue([for z in var.zones : contains(["1", "2", "3"], z)])
    error_message = "zones must be a non-empty list of \"1\", \"2\" and/or \"3\"."
  }
}

# ---------------------------------------------------------------------------
# Application Gateway + WAF
# ---------------------------------------------------------------------------

variable "appgw_min_capacity" {
  description = "Minimum Application Gateway instances (autoscale). Use 2+ so each zone failure still leaves capacity."
  type        = number
  default     = 2

  validation {
    condition     = var.appgw_min_capacity >= 0 && var.appgw_min_capacity <= 100
    error_message = "appgw_min_capacity must be between 0 and 100."
  }
}

variable "appgw_max_capacity" {
  description = "Maximum Application Gateway instances (autoscale)."
  type        = number
  default     = 5

  validation {
    condition     = var.appgw_max_capacity >= 2 && var.appgw_max_capacity <= 125
    error_message = "appgw_max_capacity must be between 2 and 125."
  }
}

variable "waf_mode" {
  description = "WAF mode. Prevention blocks matching requests. Detection only logs them (use it while tuning)."
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "waf_mode must be Prevention or Detection."
  }
}

variable "waf_owasp_version" {
  description = "OWASP Core Rule Set version for the WAF managed rules."
  type        = string
  default     = "3.2"

  validation {
    condition     = contains(["3.1", "3.2"], var.waf_owasp_version)
    error_message = "waf_owasp_version must be 3.1 or 3.2."
  }
}

# ---------------------------------------------------------------------------
# VM Scale Set
# ---------------------------------------------------------------------------

variable "vm_sku" {
  description = "VM size for the scale set instances."
  type        = string
  default     = "Standard_B2s"

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_]+$", var.vm_sku))
    error_message = "vm_sku must look like an Azure VM size, for example Standard_B2s."
  }
}

variable "admin_username" {
  description = "Admin user on the instances. Password login is disabled; only the SSH key works."
  type        = string
  default     = "azureuser"

  validation {
    condition     = !contains(["admin", "administrator", "root"], lower(var.admin_username))
    error_message = "admin_username cannot be admin, administrator or root."
  }
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the admin user (contents of ~/.ssh/id_ed25519.pub or id_rsa.pub)."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ", var.admin_ssh_public_key))
    error_message = "admin_ssh_public_key must be an OpenSSH public key (ssh-ed25519, ssh-rsa or ecdsa-sha2-nistp256)."
  }
}

variable "image" {
  description = "Marketplace image. Pin version to a real image version to control rollouts; a change triggers a rolling upgrade."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

variable "instance_count" {
  description = "Instance limits for autoscale. default is the count used when metrics are missing."
  type = object({
    minimum = number
    default = number
    maximum = number
  })
  default = {
    minimum = 2
    default = 2
    maximum = 6
  }

  validation {
    condition     = var.instance_count.minimum >= 1 && var.instance_count.minimum <= var.instance_count.default && var.instance_count.default <= var.instance_count.maximum && var.instance_count.maximum <= 100
    error_message = "instance_count must satisfy 1 <= minimum <= default <= maximum <= 100."
  }
}

# ---------------------------------------------------------------------------
# Autoscale thresholds
# ---------------------------------------------------------------------------

variable "cpu_scale_out_percent" {
  description = "Scale out by one instance when average CPU is above this value for 5 minutes."
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_scale_out_percent > 0 && var.cpu_scale_out_percent <= 100
    error_message = "cpu_scale_out_percent must be between 1 and 100."
  }
}

variable "cpu_scale_in_percent" {
  description = "Scale in by one instance when average CPU is below this value for 10 minutes."
  type        = number
  default     = 30

  validation {
    condition     = var.cpu_scale_in_percent >= 0 && var.cpu_scale_in_percent < 100
    error_message = "cpu_scale_in_percent must be between 0 and 99."
  }
}

variable "memory_scale_out_bytes" {
  description = "Scale out when average 'Available Memory Bytes' per instance drops below this value."
  type        = number
  default     = 536870912 # 512 MiB
}

variable "memory_scale_in_bytes" {
  description = "Scale in when average 'Available Memory Bytes' per instance is above this value (and CPU is low too)."
  type        = number
  default     = 1610612736 # 1.5 GiB
}

# ---------------------------------------------------------------------------
# Monitoring and alerts
# ---------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "alert_email" {
  description = "Email address that the Action Group notifies for alerts and autoscale events."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "alert_cpu_percent" {
  description = "VMSS CPU alert threshold (average over 5 minutes). Keep it above cpu_scale_out_percent: the alert means autoscale is not keeping up."
  type        = number
  default     = 85

  validation {
    condition     = var.alert_cpu_percent > 0 && var.alert_cpu_percent <= 100
    error_message = "alert_cpu_percent must be between 1 and 100."
  }
}

variable "alert_5xx_count" {
  description = "Alert when the gateway returns more than this many 5xx responses in 5 minutes."
  type        = number
  default     = 10

  validation {
    condition     = var.alert_5xx_count >= 0
    error_message = "alert_5xx_count must be 0 or more."
  }
}
