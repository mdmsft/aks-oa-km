resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "application_gateway" {
  name                 = "snet-agw"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 0)]
}

resource "azurerm_subnet" "kubernetes_cluster_default_node_pool" {
  name                 = "snet-aks-default"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}

resource "azurerm_subnet" "kubernetes_cluster_workload_node_pool" {
  name                 = "snet-aks-workload"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 2)]
}

resource "azurerm_network_security_group" "application_gateway" {
  name                = "nsg-${local.resource_suffix}-agw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowInternetIn"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerIn"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerIn"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "kubernetes_cluster_default_node_pool" {
  name                = "nsg-${local.resource_suffix}-aks-default"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "kubernetes_cluster_workload_node_pool" {
  name                = "nsg-${local.resource_suffix}-aks-workload"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "application_gateway" {
  network_security_group_id = azurerm_network_security_group.application_gateway.id
  subnet_id                 = azurerm_subnet.application_gateway.id
}

resource "azurerm_subnet_network_security_group_association" "kubernetes_cluster_default_node_pool" {
  network_security_group_id = azurerm_network_security_group.kubernetes_cluster_default_node_pool.id
  subnet_id                 = azurerm_subnet.kubernetes_cluster_default_node_pool.id
}

resource "azurerm_subnet_network_security_group_association" "kubernetes_cluster_workload_node_pool" {
  network_security_group_id = azurerm_network_security_group.kubernetes_cluster_workload_node_pool.id
  subnet_id                 = azurerm_subnet.kubernetes_cluster_workload_node_pool.id
}

resource "azurerm_public_ip_prefix" "kubernetes_cluster" {
  name                = "ippre-${local.resource_suffix}-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  prefix_length       = var.kubernetes_cluster_public_ip_prefix_length
}

locals {
  network_security_group_subnets = [
    azurerm_network_security_group.application_gateway.id,
    azurerm_network_security_group.kubernetes_cluster_default_node_pool.id,
    azurerm_network_security_group.kubernetes_cluster_workload_node_pool.id
  ]
}

resource "azurerm_monitor_diagnostic_setting" "network_security_group" {
  count              = length(local.network_security_group_subnets)
  name               = "logs"
  target_resource_id = local.network_security_group_subnets[count.index]
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
