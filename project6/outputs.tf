output "nsg_rule_names" {
  description = "All NSG rule names, using a splat expression."
  value       = azurerm_network_security_group.nsg.security_rule[*].name
}

output "nsg_name" {
  description = "NSG name chosen by the conditional expression."
  value       = azurerm_network_security_group.nsg.name
}
