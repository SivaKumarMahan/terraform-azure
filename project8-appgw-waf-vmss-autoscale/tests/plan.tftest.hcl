# Offline tests with a mocked azurerm provider. No Azure login needed.
# Run: tofu init -backend=false && tofu test

# Mocked computed values are random strings. Resource IDs are parsed by the
# provider, so give every referenced resource a well-formed ID.
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/virtualNetworks/vnet-web-dev/subnets/snet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }
  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/publicIPAddresses/pip-mock"
    }
  }
  mock_resource "azurerm_nat_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/natGateways/ng-web-dev"
    }
  }
  mock_resource "azurerm_web_application_firewall_policy" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/waf-web-dev"
    }
  }
  mock_resource "azurerm_application_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Network/applicationGateways/agw-web-dev"
    }
  }
  mock_resource "azurerm_linux_virtual_machine_scale_set" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-web-dev"
    }
  }
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.OperationalInsights/workspaces/log-web-dev"
    }
  }
  mock_resource "azurerm_monitor_autoscale_setting" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Insights/autoScaleSettings/autoscale-web-dev"
    }
  }
  mock_resource "azurerm_monitor_action_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-web-dev/providers/Microsoft.Insights/actionGroups/ag-web-dev-ops"
    }
  }
}

# Throw-away public key generated for the tests; the private key was deleted.
variables {
  admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII+DKtv9cwEqHWMY4N1BXeyWivSpY14uPCOqiT+0YErD test-only"
  alert_email          = "ops@example.com"
}

run "defaults_are_production_style" {
  command = plan

  # WAF: OWASP rule set in Prevention mode, attached to a WAF_v2 gateway in 3 zones.
  assert {
    condition     = azurerm_web_application_firewall_policy.this.policy_settings[0].mode == "Prevention"
    error_message = "WAF must run in Prevention mode by default."
  }
  assert {
    condition     = azurerm_web_application_firewall_policy.this.managed_rules[0].managed_rule_set[0].type == "OWASP"
    error_message = "WAF must use the OWASP managed rule set."
  }
  assert {
    condition     = azurerm_application_gateway.this.sku[0].tier == "WAF_v2" && length(azurerm_application_gateway.this.zones) == 3
    error_message = "Gateway must be WAF_v2 across 3 zones."
  }

  # VMSS: zones, rolling upgrades, automatic repair, boot diagnostics, SSH only.
  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.zones) == 3 && azurerm_linux_virtual_machine_scale_set.this.zone_balance
    error_message = "VMSS must be zone balanced across 3 zones."
  }
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.upgrade_mode == "Rolling"
    error_message = "VMSS must use the Rolling upgrade mode."
  }
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.automatic_instance_repair[0].enabled
    error_message = "Automatic instance repair must be on."
  }
  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.boot_diagnostics) == 1
    error_message = "Boot diagnostics must be on."
  }
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.disable_password_authentication
    error_message = "Password login must be disabled."
  }
  assert {
    condition     = contains([for e in azurerm_linux_virtual_machine_scale_set.this.extension : e.type], "ApplicationHealthLinux")
    error_message = "The Application Health extension is needed for rolling upgrades and repairs."
  }
  assert {
    condition     = strcontains(base64decode(azurerm_linux_virtual_machine_scale_set.this.custom_data), "path == \"/health\"")
    error_message = "cloud-init must install the web server with a /health endpoint."
  }

  # Only the gateway subnet reaches the instances.
  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.vmss.security_rule :
      r.access == "Allow" && r.destination_port_range == "80" && r.source_address_prefix == "10.10.1.0/24"
    ])
    error_message = "VMSS NSG must allow port 80 from the gateway subnet."
  }
  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.vmss.security_rule :
      r.access == "Deny" && r.source_address_prefix == "*" && r.direction == "Inbound"
    ])
    error_message = "VMSS NSG must deny all other inbound traffic."
  }

  # Autoscale: CPU and memory rules, two out and two in.
  assert {
    condition     = length(azurerm_monitor_autoscale_setting.vmss.profile[0].rule) == 4
    error_message = "Expected 4 autoscale rules."
  }
  assert {
    condition     = toset([for r in azurerm_monitor_autoscale_setting.vmss.profile[0].rule : r.metric_trigger[0].metric_name]) == toset(["Percentage CPU", "Available Memory Bytes"])
    error_message = "Autoscale must use CPU and memory metrics."
  }
  assert {
    condition     = length([for r in azurerm_monitor_autoscale_setting.vmss.profile[0].rule : r if r.scale_action[0].direction == "Decrease"]) == 2
    error_message = "Expected two scale-in rules."
  }

  # Alerts go to the email in the Action Group.
  assert {
    condition     = one(azurerm_monitor_action_group.ops.email_receiver).email_address == "ops@example.com"
    error_message = "Action Group must email alert_email."
  }
  assert {
    condition     = length(azurerm_monitor_action_group.ops.short_name) <= 12
    error_message = "Action Group short_name must be 12 characters or less."
  }
  assert {
    condition     = one(azurerm_monitor_metric_alert.appgw_5xx.criteria).dimension[0].values == tolist(["5xx"])
    error_message = "The 5xx alert must filter on HttpStatusGroup 5xx."
  }
}

run "detection_mode_is_allowed_for_tuning" {
  command = plan

  variables {
    waf_mode = "Detection"
  }

  assert {
    condition     = azurerm_web_application_firewall_policy.this.policy_settings[0].mode == "Detection"
    error_message = "waf_mode should flow into the policy."
  }
}

run "rejects_unknown_waf_mode" {
  command = plan

  variables {
    waf_mode = "Off"
  }

  expect_failures = [var.waf_mode]
}

run "rejects_bad_email" {
  command = plan

  variables {
    alert_email = "not-an-email"
  }

  expect_failures = [var.alert_email]
}

run "rejects_bad_instance_counts" {
  command = plan

  variables {
    instance_count = {
      minimum = 4
      default = 2
      maximum = 6
    }
  }

  expect_failures = [var.instance_count]
}

run "rejects_flapping_cpu_thresholds" {
  command = plan

  variables {
    cpu_scale_out_percent = 60
    cpu_scale_in_percent  = 65
  }

  expect_failures = [azurerm_monitor_autoscale_setting.vmss]
}
