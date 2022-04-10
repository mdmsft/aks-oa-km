locals {
  default_node_pool_total_count  = var.kubernetes_cluster_default_node_pool_max_count + (substr(var.kubernetes_cluster_default_node_pool_max_surge, -1, -1) == "%" ? ceil(var.kubernetes_cluster_default_node_pool_max_count * tonumber(trimsuffix(var.kubernetes_cluster_default_node_pool_max_surge, "%")) / 100) : tonumber(var.kubernetes_cluster_default_node_pool_max_surge))
  workload_node_pool_total_count = var.kubernetes_cluster_workload_node_pool_max_count + (substr(var.kubernetes_cluster_workload_node_pool_max_surge, -1, -1) == "%" ? ceil(var.kubernetes_cluster_workload_node_pool_max_count * tonumber(trimsuffix(var.kubernetes_cluster_workload_node_pool_max_surge, "%")) / 100) : tonumber(var.kubernetes_cluster_workload_node_pool_max_surge))
  subnets = [
    azurerm_subnet.kubernetes_cluster_default_node_pool.id,
    azurerm_subnet.kubernetes_cluster_workload_node_pool.id
  ]
}

resource "azurerm_kubernetes_cluster" "main" {
  name                              = "aks-${local.resource_suffix}"
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  dns_prefix                        = local.context_name
  automatic_channel_upgrade         = var.kubernetes_cluster_automatic_channel_upgrade
  kubernetes_version                = var.kubernetes_cluster_orchestrator_version
  sku_tier                          = var.kubernetes_cluster_sku_tier
  role_based_access_control_enabled = true
  local_account_disabled            = true
  azure_policy_enabled              = var.kubernetes_cluster_azure_policy_enabled

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  identity {
    type = "SystemAssigned"
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
    vnet_subnet_id               = azurerm_subnet.kubernetes_cluster_default_node_pool.id
    orchestrator_version         = var.kubernetes_cluster_default_node_pool_orchestrator_version == null ? var.kubernetes_cluster_orchestrator_version : var.kubernetes_cluster_default_node_pool_orchestrator_version
    zones                        = var.kubernetes_cluster_default_node_pool_availability_zones

    upgrade_settings {
      max_surge = var.kubernetes_cluster_default_node_pool_max_surge
    }
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = var.kubernetes_cluster_network_policy
    load_balancer_sku = "standard"

    load_balancer_profile {
      idle_timeout_in_minutes  = 4
      outbound_ip_prefix_ids   = [azurerm_public_ip_prefix.kubernetes_cluster.id]
      outbound_ports_allocated = ceil(64000 / (local.default_node_pool_total_count + local.workload_node_pool_total_count))
    }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.main.id
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
  vnet_subnet_id        = azurerm_subnet.kubernetes_cluster_workload_node_pool.id
  orchestrator_version  = var.kubernetes_cluster_workload_node_pool_orchestrator_version == null ? var.kubernetes_cluster_orchestrator_version : var.kubernetes_cluster_workload_node_pool_orchestrator_version
  zones                 = var.kubernetes_cluster_workload_node_pool_availability_zones
  node_labels           = var.kubernetes_cluster_workload_node_pool_labels
  node_taints           = var.kubernetes_cluster_workload_node_pool_taints

  upgrade_settings {
    max_surge = var.kubernetes_cluster_workload_node_pool_max_surge
  }
}

resource "azurerm_role_assignment" "client_aks_rbac_cluster_admin" {
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.main.id
  principal_id         = data.azurerm_client_config.main.object_id
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  count                = length(local.subnets)
  role_definition_name = "Network Contributor"
  scope                = local.subnets[count.index]
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "application_gateway" {
  for_each = {
    "Contributor"               = azurerm_application_gateway.main.id
    "Reader"                    = azurerm_resource_group.main.id
    "Managed Identity Operator" = azurerm_user_assigned_identity.application_gateway.id
  }
  scope                = each.value
  role_definition_name = each.key
  principal_id         = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}
