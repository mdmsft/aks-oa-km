locals {
  mysql_private_dns_zone_resource_group_name = split("/", var.mysql_private_dns_zone_id)[4]
  mysql_private_dns_zone_name                = reverse(split("/", var.mysql_private_dns_zone_id))[0]
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space = [
    var.address_space
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_virtual_network" "agent" {
  name                = "vnet-${local.resource_suffix}-agent"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space = [
    var.agent_address_space
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_subnet" "kubernetes_cluster" {
  name                                           = "snet-aks"
  virtual_network_name                           = azurerm_virtual_network.main.name
  resource_group_name                            = azurerm_resource_group.main.name
  address_prefixes                               = [cidrsubnet(var.address_space, 1, 0)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "private_endpoints" {
  name                                           = "snet-svc"
  virtual_network_name                           = azurerm_virtual_network.main.name
  resource_group_name                            = azurerm_resource_group.main.name
  address_prefixes                               = [cidrsubnet(var.address_space, 1, 1)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "agents" {
  name                                           = "snet-vms"
  virtual_network_name                           = azurerm_virtual_network.agent.name
  resource_group_name                            = azurerm_resource_group.main.name
  address_prefixes                               = [cidrsubnet(var.agent_address_space, 1, 0)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_network_security_group" "kubernetes_cluster" {
  name                = "nsg-${local.resource_suffix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_security_group" "agents" {
  name                = "nsg-${local.resource_suffix}-vms"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_subnet_network_security_group_association" "kubernetes_cluster" {
  network_security_group_id = azurerm_network_security_group.kubernetes_cluster.id
  subnet_id                 = azurerm_subnet.kubernetes_cluster.id
}

resource "azurerm_subnet_network_security_group_association" "agents" {
  network_security_group_id = azurerm_network_security_group.agents.id
  subnet_id                 = azurerm_subnet.agents.id
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

  lifecycle {
    ignore_changes = [
      tags,
      route
    ]
  }
}

resource "azurerm_subnet_route_table_association" "kubernetes_cluster" {
  route_table_id = azurerm_route_table.main.id
  subnet_id      = azurerm_subnet.kubernetes_cluster.id
}

resource "azurerm_subnet_route_table_association" "agents" {
  route_table_id = azurerm_route_table.main.id
  subnet_id      = azurerm_subnet.agents.id
}

resource "azurerm_virtual_network_peering" "to_firewall_network" {
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-remote"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = var.hub_virtual_network_id
  virtual_network_name         = azurerm_virtual_network.main.name
}

resource "azurerm_virtual_network_peering" "from_firewall_network" {
  provider                     = azurerm.hub
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-aks"
  resource_group_name          = split("/", var.hub_virtual_network_id)[4]
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  virtual_network_name         = reverse(split("/", var.hub_virtual_network_id))[0]
}

resource "azurerm_virtual_network_peering" "to_remote_network" {
  for_each                     = var.remote_virtual_network_ids
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-${reverse(split("/", each.value))[0]}"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = each.value
  virtual_network_name         = azurerm_virtual_network.main.name
}

resource "azurerm_virtual_network_peering" "from_remote_network" {
  for_each                     = var.remote_virtual_network_ids
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-aks"
  resource_group_name          = split("/", each.value)[4]
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  virtual_network_name         = reverse(split("/", each.value))[0]
}

resource "azurerm_virtual_network_peering" "main_agent" {
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-agent"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = azurerm_virtual_network.agent.id
  virtual_network_name         = azurerm_virtual_network.main.name
}

resource "azurerm_virtual_network_peering" "agent_main" {
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-main"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  virtual_network_name         = azurerm_virtual_network.agent.name
}

resource "azurerm_virtual_network_peering" "firewall_agent" {
  provider                     = azurerm.hub
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-agent"
  resource_group_name          = split("/", var.hub_virtual_network_id)[4]
  remote_virtual_network_id    = azurerm_virtual_network.agent.id
  virtual_network_name         = reverse(split("/", var.hub_virtual_network_id))[0]
}

resource "azurerm_virtual_network_peering" "agent_firewall" {
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-firewall"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = var.hub_virtual_network_id
  virtual_network_name         = azurerm_virtual_network.agent.name
}

resource "azurerm_virtual_network_peering" "agent_remote" {
  for_each                     = var.remote_virtual_network_ids
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-${reverse(split("/", each.value))[0]}"
  resource_group_name          = azurerm_resource_group.main.name
  remote_virtual_network_id    = each.value
  virtual_network_name         = azurerm_virtual_network.agent.name
}

resource "azurerm_virtual_network_peering" "remote_agent" {
  for_each                     = var.remote_virtual_network_ids
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  name                         = "peer-${local.resource_suffix}-agent"
  resource_group_name          = split("/", each.value)[4]
  remote_virtual_network_id    = azurerm_virtual_network.agent.id
  virtual_network_name         = reverse(split("/", each.value))[0]
}


resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = azurerm_virtual_network.main.name
  private_dns_zone_name = local.mysql_private_dns_zone_name
  resource_group_name   = local.mysql_private_dns_zone_resource_group_name
  registration_enabled  = false
  virtual_network_id    = azurerm_virtual_network.main.id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
