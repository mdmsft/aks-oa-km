output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kubernetes_context_name" {
  value = local.resource_suffix
}

output "container_registry_name" {
  value = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "application_gateway_fqdn" {
  value = azurerm_public_ip.application_gateway.fqdn
}
