variable "project" { type = string }
variable "env" { type = string }
variable "location" { type = string }

variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }

variable "vnet_cidr" { type = string }
variable "aks_subnet_cidr" { type = string }
variable "bastion_subnet_cidr" { type = string }

variable "kubernetes_version" { type = string }
variable "system_node_count" { type = number }
variable "system_vm_size" { type = string }
variable "public_network_access_enabled" { type = bool }
variable "local_account_disabled" { type = bool }
variable "azure_policy_enabled" { type = bool }
variable "enable_aad_rbac" { type = bool }
variable "aad_admin_group_object_ids" { type = list(string) }
variable "api_server_authorized_ip_ranges" { type = list(string) }
variable "outbound_type" { type = string }
variable "load_balancer_sku" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_jumpbox" {
  type    = bool
  default = true
}

variable "keyvault_public_network_access_enabled" { type = bool }
variable "keyvault_purge_protection_enabled" { type = bool }
variable "keyvault_soft_delete_retention_days" { type = number }
variable "keyvault_enable_network_acls" { type = bool }
variable "keyvault_network_acls_default_action" { type = string }
variable "keyvault_network_acls_bypass" { type = string }

variable "jumpbox_admin_username" { type = string }
variable "jumpbox_ssh_public_key" { type = string }
variable "jumpbox_vm_size" { type = string }
