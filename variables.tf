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

variable "address_space" {
  type    = string
  default = "172.17.0.0/16"
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

variable "kubernetes_cluster_default_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "kubernetes_cluster_default_node_pool_max_pods" {
  type    = number
  default = 30
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
  default = 30
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
  default = "azure"
}

variable "application_gateway_autoscale_configuration_min_capacity" {
  type    = number
  default = 1
}

variable "application_gateway_autoscale_configuration_max_capacity" {
  type    = number
  default = 3
}

variable "application_gateway_enable_http2" {
  type    = bool
  default = true
}

variable "web_application_firewall_policy_mode" {
  type    = string
  default = "Prevention"
}

variable "web_application_firewall_policy_file_upload_limit_in_mb" {
  type    = number
  default = 100
}

variable "web_application_firewall_policy_max_request_body_size_in_kb" {
  type    = number
  default = 128
}

variable "web_application_firewall_policy_request_body_check" {
  type    = bool
  default = true
}
