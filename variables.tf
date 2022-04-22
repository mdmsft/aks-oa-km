variable "project" {
  type    = string
  default = "km"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "hub_subscription_id" {
  type = string
}

variable "kubernetes_cluster_admin_principal_id" {
  type = string
}

variable "firewall_ip_address" {
  type = string
}

variable "hub_virtual_network_id" {
  type = string
}

variable "production_virtual_network_id" {
  type = string
}

variable "container_registry_private_dns_zone_id" {
  type = string
}

variable "mysql_private_dns_zone_id" {
  type = string
}

variable "address_space" {
  type    = string
  default = "10.218.36.0/26"
}

variable "kubernetes_cluster_public_ip_prefix_length" {
  type    = number
  default = 31
}

variable "kubernetes_cluster_orchestrator_version" {
  type    = string
  default = "1.22.6"
}

variable "kubernetes_cluster_sku_tier" {
  type    = string
  default = "Paid"
}

variable "kubernetes_cluster_automatic_channel_upgrade" {
  type    = string
  default = "stable"
}

variable "kubernetes_cluster_azure_policy_enabled" {
  type    = bool
  default = true
}

variable "kubernetes_cluster_pod_cidr" {
  type    = string
  default = "192.168.0.0/16"
}

variable "kubernetes_cluster_service_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "kubernetes_cluster_docker_bridge_cidr" {
  type    = string
  default = "172.16.0.0/24"
}

variable "kubernetes_cluster_default_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "kubernetes_cluster_default_node_pool_max_pods" {
  type    = number
  default = 110
}

variable "kubernetes_cluster_default_node_pool_min_count" {
  type    = number
  default = 1
}

variable "kubernetes_cluster_default_node_pool_max_count" {
  type    = number
  default = 3
}

variable "kubernetes_cluster_default_node_pool_os_disk_size_gb" {
  type    = number
  default = 30
}

variable "kubernetes_cluster_default_node_pool_os_disk_type" {
  type    = string
  default = "Ephemeral"
}

variable "kubernetes_cluster_default_node_pool_os_sku" {
  type    = string
  default = "Ubuntu"
}

variable "kubernetes_cluster_default_node_pool_max_surge" {
  type    = string
  default = "33%"
}

variable "kubernetes_cluster_default_node_pool_availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "kubernetes_cluster_default_node_pool_orchestrator_version" {
  type     = string
  default  = null
  nullable = true
}

variable "kubernetes_cluster_workload_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "kubernetes_cluster_workload_node_pool_max_pods" {
  type    = number
  default = 110
}

variable "kubernetes_cluster_workload_node_pool_min_count" {
  type    = number
  default = 1
}

variable "kubernetes_cluster_workload_node_pool_max_count" {
  type    = number
  default = 3
}

variable "kubernetes_cluster_workload_node_pool_os_disk_size_gb" {
  type    = number
  default = 30
}

variable "kubernetes_cluster_workload_node_pool_os_disk_type" {
  type    = string
  default = "Ephemeral"
}

variable "kubernetes_cluster_workload_node_pool_os_sku" {
  type    = string
  default = "Ubuntu"
}

variable "kubernetes_cluster_workload_node_pool_max_surge" {
  type    = string
  default = "33%"
}

variable "kubernetes_cluster_workload_node_pool_availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "kubernetes_cluster_workload_node_pool_orchestrator_version" {
  type     = string
  default  = null
  nullable = true
}

variable "kubernetes_cluster_workload_node_pool_labels" {
  type    = map(string)
  default = {}
}

variable "kubernetes_cluster_workload_node_pool_taints" {
  type    = list(string)
  default = []
}

variable "kubernetes_cluster_network_policy" {
  type    = string
  default = "calico"
}
