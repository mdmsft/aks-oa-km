output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kubernetes_context_name" {
  value = local.resource_suffix
}
