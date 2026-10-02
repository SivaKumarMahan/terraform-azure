output "nsg_rule_names" {
  value = [for rule in azurerm_network_security_group.nsg.security_rule : rule.name]
}

output "nsg_name" {
  value = azurerm_network_security_group.nsg.name
}

output "assignment1_formatted_name" {
  description = "Project name normalized"
  value       = local.formatted_name
}

output "assignment2_tags" {
  description = "Merged tags"
  value       = local.merged_tags
}

output "assignment3_storage_name" {
  description = "Normalized storage account name (<=23 chars, lowercase, alnum)"
  value       = local.storage_normalized
}

output "assignment4_ports_doc" {
  description = "Formatted ports string"
  value       = local.ports_joined
  # fail-fast if ports invalid (fail at plan)
  sensitive = false
}

output "assignment4_ports_validation" {
  value = local.ports_valid
}

output "assignment5_env_config" {
  value = local.env_config
}

output "assignment6_vm_size" {
  value = local.vm_size_local
}

output "backup_configuration" {
  description = "Validated and secure backup configuration output"
  value = {
    backup_name = var.backup_name
    credential  = local.secure_credential
  }
  sensitive = true
}

output "file_validation_status" {
  description = "Shows file existence and directory info"
  value       = local.file_status
}

output "assignment9_unique_locations" {
  description = "Unique locations from toset(concat(...))"
  value       = local.unique_locations
}

output "assignment11_dates" {
  description = "Formatted timestamps. They change on every plan because timestamp() is not stable."
  value = {
    name_date = local.name_date
    tag_date  = local.tag_date
  }
}

output "cost_report" {
  description = "Monthly cost report (positive, max, avg)"
  value = {
    positive_costs = local.positive_costs
    max_cost       = local.max_cost
    avg_cost       = local.avg_cost
  }
}