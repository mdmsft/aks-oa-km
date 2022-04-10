locals {
  backend_address_pool_name      = "default"
  backend_http_setting_name      = "default"
  frontend_port_name             = "default"
  frontend_ip_configuration_name = "default"
  gateway_ip_configuration_name  = "default"
  listener_name                  = "default"
  request_routing_rule_name      = "default"
}

resource "azurerm_public_ip" "application_gateway" {
  name                = "pip-${local.resource_suffix}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.context_name
}

resource "azurerm_user_assigned_identity" "application_gateway" {
  name                = "id-${local.resource_suffix}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "waf-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = var.web_application_firewall_policy_mode
    file_upload_limit_in_mb     = var.web_application_firewall_policy_file_upload_limit_in_mb
    max_request_body_size_in_kb = var.web_application_firewall_policy_max_request_body_size_in_kb
    request_body_check          = var.web_application_firewall_policy_request_body_check
  }
}

resource "azurerm_application_gateway" "main" {
  name                              = "agw-${local.resource_suffix}"
  resource_group_name               = azurerm_resource_group.main.name
  location                          = azurerm_resource_group.main.location
  firewall_policy_id                = azurerm_web_application_firewall_policy.main.id
  enable_http2                      = var.application_gateway_enable_http2
  force_firewall_policy_association = true

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.application_gateway.id]
  }

  autoscale_configuration {
    min_capacity = var.application_gateway_autoscale_configuration_min_capacity
    max_capacity = var.application_gateway_autoscale_configuration_max_capacity
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.application_gateway.id
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.application_gateway.id
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_setting_name
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      request_routing_rule,
      probe,
      rewrite_rule_set,
      redirect_configuration
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "public_ip_application_gateway" {
  name               = "logs"
  target_resource_id = azurerm_public_ip.application_gateway.id
  storage_account_id = azurerm_storage_account.logs.id

  dynamic "log" {
    for_each = toset([
      "DDoSProtectionNotifications",
      "DDoSMitigationFlowLogs",
      "DDoSMitigationReports"
    ])

    content {
      enabled  = true
      category = log.value

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  name               = "logs"
  target_resource_id = azurerm_application_gateway.main.id
  storage_account_id = azurerm_storage_account.logs.id

  dynamic "log" {
    for_each = toset([
      "ApplicationGatewayAccessLog",
      "ApplicationGatewayPerformanceLog",
      "ApplicationGatewayFirewallLog"
    ])

    content {
      enabled  = true
      category = log.value

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}
