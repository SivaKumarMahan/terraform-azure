variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the ARM_SUBSCRIPTION_ID environment variable."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "centralindia"
}

variable "prefix" {
  description = "Short name used in resource names, for example data-dev. Max 14 characters (Key Vault names are limited to 24)."
  type        = string
  default     = "data-dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,13}$", var.prefix))
    error_message = "prefix must be 3-14 characters: lowercase letters, digits and '-', starting with a letter."
  }
}

variable "resource_group_name" {
  description = "Resource group to create for this project."
  type        = string
  default     = "rg-data-dev"
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
    project     = "project9-postgresql-private-backup-rbac"
  }
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space of the VNet."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "vnet_address_space must be a valid IPv4 CIDR."
  }
}

variable "subnet_prefixes" {
  description = "Subnet CIDRs: postgres (delegated to Flexible Server), endpoints (private endpoints), vm (test VM)."
  type = object({
    postgres  = string
    endpoints = string
    vm        = string
  })
  default = {
    postgres  = "10.20.1.0/24"
    endpoints = "10.20.2.0/24"
    vm        = "10.20.3.0/24"
  }

  validation {
    condition     = alltrue([for c in values(var.subnet_prefixes) : can(cidrhost(c, 0))])
    error_message = "Every subnet prefix must be a valid IPv4 CIDR."
  }
}

# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server
# ---------------------------------------------------------------------------

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"

  validation {
    condition     = contains(["14", "15", "16", "17"], var.postgres_version)
    error_message = "postgres_version must be 14, 15, 16 or 17."
  }
}

variable "postgres_sku" {
  description = "Compute SKU. B_ = Burstable, GP_ = General Purpose, MO_ = Memory Optimized."
  type        = string
  default     = "GP_Standard_D2ds_v5"

  validation {
    condition     = can(regex("^(B|GP|MO)_Standard_[A-Za-z0-9_]+$", var.postgres_sku))
    error_message = "postgres_sku must look like B_Standard_B1ms, GP_Standard_D2ds_v5 or MO_Standard_E2ds_v5."
  }
}

variable "postgres_storage_mb" {
  description = "Storage size in MB. Auto-grow is on, so this is the starting size."
  type        = number
  default     = 32768

  validation {
    condition     = contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408], var.postgres_storage_mb)
    error_message = "postgres_storage_mb must be one of the sizes Azure allows (32768, 65536, 131072, ...)."
  }
}

variable "postgres_zone" {
  description = "Availability zone for the server. Use null in regions without zones."
  type        = string
  default     = "1"

  validation {
    condition     = var.postgres_zone == null ? true : contains(["1", "2", "3"], var.postgres_zone)
    error_message = "postgres_zone must be \"1\", \"2\", \"3\" or null."
  }
}

variable "postgres_admin_login" {
  description = "Local admin login (break-glass only; people log in with Entra ID). The password is generated."
  type        = string
  default     = "pgadmin"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.postgres_admin_login)) && !contains(["admin", "administrator", "root", "guest", "public", "azure_superuser", "azure_pg_admin", "postgres"], var.postgres_admin_login) && !startswith(var.postgres_admin_login, "pg_")
    error_message = "postgres_admin_login must be lowercase, start with a letter, not be a reserved name, and not start with pg_."
  }
}

variable "backup_retention_days" {
  description = "Point-in-time restore window in days."
  type        = number
  default     = 14

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Copy backups to the paired region. Can only be set when the server is created (changing it replaces the server)."
  type        = bool
  default     = false
}

variable "server_parameters" {
  description = "Server parameters (azurerm_postgresql_flexible_server_configuration), name => value."
  type        = map(string)
  default = {
    "require_secure_transport"            = "on"
    "log_min_duration_statement"          = "1000"
    "idle_in_transaction_session_timeout" = "600000"
    "azure.extensions"                    = "PG_STAT_STATEMENTS,PGCRYPTO"
  }
}

variable "database_name" {
  description = "Application database to create."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must be lowercase letters, digits or '_', starting with a letter."
  }
}

# ---------------------------------------------------------------------------
# Entra ID
# ---------------------------------------------------------------------------

variable "entra_admin_object_id" {
  description = "Object ID of the Entra ID group (or user) that becomes PostgreSQL admin."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.entra_admin_object_id))
    error_message = "entra_admin_object_id must be a GUID."
  }
}

variable "entra_admin_principal_name" {
  description = "Display name of that group or user. This is the role name used to log in to PostgreSQL."
  type        = string

  validation {
    condition     = length(trimspace(var.entra_admin_principal_name)) > 0
    error_message = "entra_admin_principal_name must not be empty."
  }
}

variable "entra_admin_principal_type" {
  description = "Type of the Entra ID admin principal."
  type        = string
  default     = "Group"

  validation {
    condition     = contains(["Group", "User", "ServicePrincipal"], var.entra_admin_principal_type)
    error_message = "entra_admin_principal_type must be Group, User or ServicePrincipal."
  }
}

variable "operators_group_object_id" {
  description = "Object ID of the Entra ID group that gets the custom VM operator role."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.operators_group_object_id))
    error_message = "operators_group_object_id must be a GUID."
  }
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

variable "key_vault_allowed_ips" {
  description = "Public IPs/CIDRs allowed through the Key Vault firewall (for example your runner's IP). Empty = public access off; run from inside the VNet."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.key_vault_allowed_ips : can(cidrhost(strcontains(ip, "/") ? ip : "${ip}/32", 0))])
    error_message = "key_vault_allowed_ips must be IPv4 addresses or CIDRs."
  }
}

variable "key_vault_purge_protection" {
  description = "Turn on purge protection. Use true in production. It cannot be turned off again."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Test VM + Azure Backup
# ---------------------------------------------------------------------------

variable "vm_size" {
  description = "Size of the small test VM (also used as a psql jump box inside the VNet)."
  type        = string
  default     = "Standard_B1s"

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_]+$", var.vm_size))
    error_message = "vm_size must look like an Azure VM size, for example Standard_B1s."
  }
}

variable "admin_username" {
  description = "Admin user on the test VM. SSH key only."
  type        = string
  default     = "azureuser"

  validation {
    condition     = !contains(["admin", "administrator", "root"], lower(var.admin_username))
    error_message = "admin_username cannot be admin, administrator or root."
  }
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the test VM."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ", var.admin_ssh_public_key))
    error_message = "admin_ssh_public_key must be an OpenSSH public key."
  }
}

variable "vault_storage_mode" {
  description = "Recovery Services Vault storage redundancy. Set it before the first backup; it is locked after that."
  type        = string
  default     = "GeoRedundant"

  validation {
    condition     = contains(["GeoRedundant", "ZoneRedundant", "LocallyRedundant"], var.vault_storage_mode)
    error_message = "vault_storage_mode must be GeoRedundant, ZoneRedundant or LocallyRedundant."
  }
}

variable "cross_region_restore_enabled" {
  description = "Allow restores in the paired region. Needs vault_storage_mode = GeoRedundant."
  type        = bool
  default     = false
}

variable "vm_backup" {
  description = "VM backup policy: daily time (UTC) and how many daily/weekly/monthly/yearly recovery points to keep. yearly = 0 turns yearly retention off."
  type = object({
    time    = string
    daily   = number
    weekly  = number
    monthly = number
    yearly  = number
  })
  default = {
    time    = "23:00"
    daily   = 14
    weekly  = 8
    monthly = 12
    yearly  = 1
  }

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):(00|30)$", var.vm_backup.time))
    error_message = "vm_backup.time must be HH:00 or HH:30 (24h)."
  }

  validation {
    condition     = var.vm_backup.daily >= 7 && var.vm_backup.daily <= 9999 && var.vm_backup.weekly >= 1 && var.vm_backup.weekly <= 5163 && var.vm_backup.monthly >= 1 && var.vm_backup.monthly <= 1188 && var.vm_backup.yearly >= 0 && var.vm_backup.yearly <= 99
    error_message = "Retention counts: daily 7-9999, weekly 1-5163, monthly 1-1188, yearly 0-99."
  }
}
