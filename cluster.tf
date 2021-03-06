locals {
  default_node_pool_total_count  = var.kubernetes_cluster_default_node_pool_max_count + (substr(var.kubernetes_cluster_default_node_pool_max_surge, -1, -1) == "%" ? ceil(var.kubernetes_cluster_default_node_pool_max_count * tonumber(trimsuffix(var.kubernetes_cluster_default_node_pool_max_surge, "%")) / 100) : tonumber(var.kubernetes_cluster_default_node_pool_max_surge))
  workload_node_pool_total_count = var.kubernetes_cluster_workload_node_pool_max_count + (substr(var.kubernetes_cluster_workload_node_pool_max_surge, -1, -1) == "%" ? ceil(var.kubernetes_cluster_workload_node_pool_max_count * tonumber(trimsuffix(var.kubernetes_cluster_workload_node_pool_max_surge, "%")) / 100) : tonumber(var.kubernetes_cluster_workload_node_pool_max_surge))
}

resource "azurerm_user_assigned_identity" "kubernetes_cluster" {
  name                = "id-${local.resource_suffix}-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                                = "aks-${local.resource_suffix}"
  location                            = azurerm_resource_group.main.location
  resource_group_name                 = azurerm_resource_group.main.name
  dns_prefix                          = local.context_name
  automatic_channel_upgrade           = var.kubernetes_cluster_automatic_channel_upgrade
  kubernetes_version                  = var.kubernetes_cluster_orchestrator_version
  sku_tier                            = var.kubernetes_cluster_sku_tier
  role_based_access_control_enabled   = true
  local_account_disabled              = true
  azure_policy_enabled                = var.kubernetes_cluster_azure_policy_enabled
  public_network_access_enabled       = false
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.kubernetes_cluster.id]
  }

  default_node_pool {
    name                         = "default"
    type                         = "VirtualMachineScaleSets"
    vm_size                      = var.kubernetes_cluster_default_node_pool_vm_size
    enable_auto_scaling          = true
    min_count                    = var.kubernetes_cluster_default_node_pool_min_count
    max_count                    = var.kubernetes_cluster_default_node_pool_max_count
    max_pods                     = var.kubernetes_cluster_default_node_pool_max_pods
    os_disk_size_gb              = var.kubernetes_cluster_default_node_pool_os_disk_size_gb
    os_disk_type                 = var.kubernetes_cluster_default_node_pool_os_disk_type
    os_sku                       = var.kubernetes_cluster_default_node_pool_os_sku
    only_critical_addons_enabled = true
    vnet_subnet_id               = azurerm_subnet.kubernetes_cluster.id
    orchestrator_version         = var.kubernetes_cluster_default_node_pool_orchestrator_version == null ? var.kubernetes_cluster_orchestrator_version : var.kubernetes_cluster_default_node_pool_orchestrator_version
    zones                        = var.kubernetes_cluster_default_node_pool_availability_zones

    upgrade_settings {
      max_surge = var.kubernetes_cluster_default_node_pool_max_surge
    }
  }

  network_profile {
    network_plugin     = "kubenet"
    network_policy     = var.kubernetes_cluster_network_policy
    load_balancer_sku  = "standard"
    pod_cidr           = var.kubernetes_cluster_pod_cidr
    service_cidr       = var.kubernetes_cluster_service_cidr
    dns_service_ip     = cidrhost(var.kubernetes_cluster_service_cidr, 10)
    docker_bridge_cidr = var.kubernetes_cluster_docker_bridge_cidr
    outbound_type      = "userDefinedRouting"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  depends_on = [
    azurerm_subnet_route_table_association.kubernetes_cluster,
    azurerm_role_assignment.kubernetes_cluster_managed_identity,
    azurerm_virtual_network_peering.to_firewall_network,
    azurerm_virtual_network_peering.from_firewall_network,
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "main" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.kubernetes_cluster_workload_node_pool_vm_size
  enable_auto_scaling   = true
  min_count             = var.kubernetes_cluster_workload_node_pool_min_count
  max_count             = var.kubernetes_cluster_workload_node_pool_max_count
  max_pods              = var.kubernetes_cluster_workload_node_pool_max_pods
  os_disk_size_gb       = var.kubernetes_cluster_workload_node_pool_os_disk_size_gb
  os_disk_type          = var.kubernetes_cluster_workload_node_pool_os_disk_type
  os_sku                = var.kubernetes_cluster_workload_node_pool_os_sku
  vnet_subnet_id        = azurerm_subnet.kubernetes_cluster.id
  orchestrator_version  = var.kubernetes_cluster_workload_node_pool_orchestrator_version == null ? var.kubernetes_cluster_orchestrator_version : var.kubernetes_cluster_workload_node_pool_orchestrator_version
  zones                 = var.kubernetes_cluster_workload_node_pool_availability_zones
  node_labels           = var.kubernetes_cluster_workload_node_pool_labels
  node_taints           = var.kubernetes_cluster_workload_node_pool_taints

  upgrade_settings {
    max_surge = var.kubernetes_cluster_workload_node_pool_max_surge
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_role_assignment" "client_aks_rbac_cluster_admin" {
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.main.id
  principal_id         = var.kubernetes_cluster_admin_principal_id
}

resource "azurerm_role_assignment" "agent_aks_rbac_cluster_admin" {
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.main.id
  principal_id         = azurerm_linux_virtual_machine_scale_set.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "kubernetes_cluster_managed_identity" {
  for_each = {
    "Network Contributor" = azurerm_subnet.kubernetes_cluster.id
    "Contributor"         = azurerm_route_table.main.id
  }
  role_definition_name = each.key
  scope                = each.value
  principal_id         = azurerm_user_assigned_identity.kubernetes_cluster.principal_id
}
