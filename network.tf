resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "kubernetes_cluster" {
  name                 = "snet-aks"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 0, 1)]
}

resource "azurerm_network_security_group" "kubernetes_cluster" {
  name                = "nsg-${local.resource_suffix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "kubernetes_cluster" {
  network_security_group_id = azurerm_network_security_group.kubernetes_cluster.id
  subnet_id                 = azurerm_subnet.kubernetes_cluster.id
}

resource "azurerm_public_ip_prefix" "kubernetes_cluster" {
  name                = "ippre-${local.resource_suffix}-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  prefix_length       = var.kubernetes_cluster_public_ip_prefix_length
}

resource "azurerm_monitor_diagnostic_setting" "network_security_group" {
  name               = "logs"
  target_resource_id = azurerm_network_security_group.kubernetes_cluster.id
  storage_account_id = azurerm_storage_account.logs.id

  dynamic "log" {
    for_each = toset([
      "NetworkSecurityGroupEvent",
      "NetworkSecurityGroupRuleCounter"
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
