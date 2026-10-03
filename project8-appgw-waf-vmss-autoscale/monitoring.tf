# ---------------------------------------------------------------------------
# Log Analytics + diagnostic settings
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Access, performance and firewall (WAF) logs go to resource-specific tables:
# AGWAccessLogs, AGWPerformanceLogs, AGWFirewallLogs.
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                           = "to-log-analytics"
  target_resource_id             = azurerm_application_gateway.this.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Why did autoscale (not) scale? AutoscaleEvaluations and AutoscaleScaleActions answer that.
resource "azurerm_monitor_diagnostic_setting" "autoscale" {
  name                       = "to-log-analytics"
  target_resource_id         = azurerm_monitor_autoscale_setting.vmss.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# ---------------------------------------------------------------------------
# Autoscale: CPU and memory, scale out fast, scale in slowly
# ---------------------------------------------------------------------------

locals {
  vmss_metric_namespace = "microsoft.compute/virtualmachinescalesets"
}

resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "autoscale-${var.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
  tags                = var.tags

  profile {
    name = "default"

    capacity {
      minimum = var.instance_count.minimum
      default = var.instance_count.default
      maximum = var.instance_count.maximum
    }

    # Scale OUT: any one rule is enough.
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = local.vmss_metric_namespace
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.cpu_scale_out_percent
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Available Memory Bytes"
        metric_namespace   = local.vmss_metric_namespace
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.memory_scale_out_bytes
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale IN: Azure only scales in when ALL scale-in rules are true,
    # so a low-CPU but memory-hungry pool is not shrunk.
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = local.vmss_metric_namespace
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.cpu_scale_in_percent
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Available Memory Bytes"
        metric_namespace   = local.vmss_metric_namespace
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.memory_scale_in_bytes
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  notification {
    email {
      custom_emails = [var.alert_email]
    }
  }

  lifecycle {
    precondition {
      condition     = var.cpu_scale_in_percent < var.cpu_scale_out_percent
      error_message = "cpu_scale_in_percent must be lower than cpu_scale_out_percent, or autoscale will flap."
    }
    precondition {
      condition     = var.memory_scale_out_bytes < var.memory_scale_in_bytes
      error_message = "memory_scale_out_bytes must be lower than memory_scale_in_bytes, or autoscale will flap."
    }
  }
}

# ---------------------------------------------------------------------------
# Alerts -> Action Group (email)
# ---------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "ops" {
  name                = "ag-${var.prefix}-ops"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = substr(replace("ops${var.prefix}", "-", ""), 0, 12)
  tags                = var.tags

  email_receiver {
    name                    = "ops-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "vmss_cpu" {
  name                = "alert-${var.prefix}-vmss-cpu-high"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_linux_virtual_machine_scale_set.this.id]
  description         = "VMSS average CPU is above ${var.alert_cpu_percent}% for 5 minutes. Autoscale may be at its maximum."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alert_cpu_percent
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

resource "azurerm_monitor_metric_alert" "appgw_unhealthy_hosts" {
  name                = "alert-${var.prefix}-agw-unhealthy-hosts"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_application_gateway.this.id]
  description         = "At least one backend instance fails the /health probe."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

resource "azurerm_monitor_metric_alert" "appgw_5xx" {
  name                = "alert-${var.prefix}-agw-5xx"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_application_gateway.this.id]
  description         = "The gateway returned more than ${var.alert_5xx_count} 5xx responses in 5 minutes."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "ResponseStatus"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.alert_5xx_count

    dimension {
      name     = "HttpStatusGroup"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}
