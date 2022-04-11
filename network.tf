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
  address_prefixes     = [cidrsubnet(var.address_space, 1, 0)]
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

resource "azurerm_route_table" "main" {
  name                = "rt-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_in_ip_address = var.firewall_ip_address
    next_hop_type          = "VirtualAppliance"
  }
}

resource "azurerm_subnet_route_table_association" "kubernetes_cluster" {
  route_table_id = azurerm_route_table.main.id
  subnet_id      = azurerm_subnet.kubernetes_cluster.id
}

resource "azurerm_virtual_network_peering" "to_firewall_network" {
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  name                         = "peer-${local.resource_suffix}-remote"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = var.remote_virtual_network_id
  virtual_network_name         = azurerm_virtual_network.main.name
}

resource "azurerm_virtual_network_peering" "from_firewall_network" {
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  name                         = "peer-${local.resource_suffix}-aks"
  resource_group_name          = split("/", var.remote_virtual_network_id)[4]
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  virtual_network_name         = reverse(split("/", var.remote_virtual_network_id))[0]
}
