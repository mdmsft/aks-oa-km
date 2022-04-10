resource "azurerm_container_registry" "main" {
  name                   = "cr${local.safe_resource_suffix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  sku                    = "Basic"
  admin_enabled          = false
  anonymous_pull_enabled = false
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main.id
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
}

resource "azurerm_monitor_diagnostic_setting" "container_registry" {
  name               = "logs"
  target_resource_id = azurerm_container_registry.main.id
  storage_account_id = azurerm_storage_account.logs.id

  dynamic "log" {
    for_each = toset([
      "ContainerRegistryRepositoryEvents",
      "ContainerRegistryLoginEvents"
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
