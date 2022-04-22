locals {
  container_registry_private_dns_zone_resource_group_name = split("/", var.container_registry_private_dns_zone_id)[4]
  container_registry_private_dns_zone_name                = reverse(split("/", var.container_registry_private_dns_zone_id))[0]
}

resource "azurerm_container_registry" "main" {
  name                          = "cr${var.project}${var.environment}weu"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  admin_enabled                 = false
  sku                           = "Premium"
  anonymous_pull_enabled        = false
  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main.id
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = azurerm_virtual_network.main.name
  provider              = azurerm.hub
  private_dns_zone_name = local.container_registry_private_dns_zone_name
  resource_group_name   = local.container_registry_private_dns_zone_resource_group_name
  registration_enabled  = false
  virtual_network_id    = azurerm_virtual_network.main.id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_private_endpoint" "container_registry" {
  name                = "pe-${local.resource_suffix}-cr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = azurerm_container_registry.main.name
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = local.container_registry_private_dns_zone_name
    private_dns_zone_ids = [var.container_registry_private_dns_zone_id]
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
