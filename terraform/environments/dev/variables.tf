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

variable "tags" {
  type    = map(string)
  default = {}
}

variable "jumpbox_admin_username" { type = string }
variable "jumpbox_ssh_public_key" { type = string }
