resource "azurerm_storage_account" "logs" {
  name                            = "st${local.safe_resource_suffix}logs"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  access_tier                     = "Cool"
  allow_nested_items_to_be_public = false
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  daily_quota_gb      = 1
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "log_analytics_workspace" {
  name               = "logs"
  target_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_id = azurerm_storage_account.logs.id

  log {
    enabled  = true
    category = "Audit"

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}
