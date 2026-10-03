output "resource_group_name" {
  description = "Resource group that holds everything."
  value       = azurerm_resource_group.this.name
}

output "app_url" {
  description = "Public URL of the Application Gateway."
  value       = "http://${azurerm_public_ip.appgw.ip_address}/"
}

output "health_url" {
  description = "Health endpoint through the gateway."
  value       = "http://${azurerm_public_ip.appgw.ip_address}/health"
}

output "application_gateway_name" {
  description = "Application Gateway name (for az network application-gateway commands)."
  value       = azurerm_application_gateway.this.name
}

output "waf_policy_id" {
  description = "ID of the WAF policy attached to the gateway."
  value       = azurerm_web_application_firewall_policy.this.id
}

output "vmss_name" {
  description = "VM Scale Set name."
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "nat_outbound_ip" {
  description = "Public IP that the instances use for outbound traffic."
  value       = azurerm_public_ip.nat.ip_address
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (GUID) for az monitor log-analytics query."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "action_group_id" {
  description = "Action Group that receives the alerts."
  value       = azurerm_monitor_action_group.ops.id
}
