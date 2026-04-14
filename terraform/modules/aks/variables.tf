variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "aks_identity_id" { type = string }
variable "kubernetes_version" { type = string }
variable "system_node_count" { type = number }
variable "system_vm_size" { type = string }

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers. Requires log_analytics_workspace_id."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Microsoft Defender for Containers. Required when enable_defender = true."
  type        = string
  default     = ""
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Disable public network access to AKS API server (recommended: false for production)"
}

variable "local_account_disabled" {
  type        = bool
  default     = true
  description = "Disable local Kubernetes accounts — enforce AAD-only access"
}

variable "azure_policy_enabled" {
  type        = bool
  default     = true
  description = "Enable Azure Policy add-on for compliance enforcement"
}

variable "enable_aad_rbac" {
  type    = bool
  default = false
}

variable "aad_admin_group_object_ids" {
  type    = list(string)
  default = []
  validation {
    condition     = !var.enable_aad_rbac || length(var.aad_admin_group_object_ids) > 0
    error_message = "aad_admin_group_object_ids must be set when enable_aad_rbac is true."
  }
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  default     = []
  description = "IP ranges allowed to reach the AKS API server. Leave empty for private cluster with no additional restrictions."
}

variable "outbound_type" {
  type    = string
  default = "loadBalancer"
  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway", "none"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway, or none."
  }
}

variable "load_balancer_sku" {
  type    = string
  default = "standard"
  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "load_balancer_sku must be basic or standard."
  }
}

variable "tags" { type = map(string) }
