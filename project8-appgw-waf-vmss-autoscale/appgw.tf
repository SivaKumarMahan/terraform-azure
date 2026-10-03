locals {
  appgw_name            = "agw-${var.prefix}"
  gateway_ip_config     = "gw-ipcfg"
  frontend_ip_config    = "fe-public"
  frontend_port_http    = "fe-port-80"
  backend_pool          = "be-vmss"
  backend_http_settings = "be-http-80"
  health_probe          = "probe-health"
  http_listener         = "listener-http"
  routing_rule          = "rule-http-to-vmss"
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-${var.prefix}-agw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

# WAF policy: OWASP Core Rule Set in Prevention mode.
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "waf-${var.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = var.waf_owasp_version
    }
  }
}

resource "azurerm_application_gateway" "this" {
  name                = local.appgw_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  zones               = var.zones
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  http2_enabled       = true
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = var.appgw_min_capacity
    max_capacity = var.appgw_max_capacity
  }

  # Older default TLS policies are retired; pin a current predefined one.
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_config
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_port_http
    port = 80
  }

  # The VMSS NICs register themselves in this pool (see vmss.tf).
  backend_address_pool {
    name = local.backend_pool
  }

  probe {
    name                = local.health_probe
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = "/health"
    interval            = 15
    timeout             = 10
    unhealthy_threshold = 3

    match {
      status_code = ["200"]
    }
  }

  backend_http_settings {
    name                  = local.backend_http_settings
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe_name            = local.health_probe

    # Finish in-flight requests when an instance leaves the pool (scale-in, rolling upgrade).
    connection_draining {
      enabled           = true
      drain_timeout_sec = 60
    }
  }

  http_listener {
    name                           = local.http_listener
    frontend_ip_configuration_name = local.frontend_ip_config
    frontend_port_name             = local.frontend_port_http
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.routing_rule
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener
    backend_address_pool_name  = local.backend_pool
    backend_http_settings_name = local.backend_http_settings
  }

  lifecycle {
    precondition {
      condition     = var.appgw_min_capacity <= var.appgw_max_capacity
      error_message = "appgw_min_capacity must not be greater than appgw_max_capacity."
    }
  }

  depends_on = [azurerm_subnet_network_security_group_association.appgw]
}
