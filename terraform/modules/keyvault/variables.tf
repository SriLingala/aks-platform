variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "purge_protection_enabled" {
  type    = bool
  default = false
}

variable "soft_delete_retention_days" {
  type    = number
  default = 7
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "enable_network_acls" {
  type    = bool
  default = false
}

variable "network_acls_default_action" {
  type    = string
  default = "Allow"
  validation {
    condition     = var.network_acls_default_action == "Allow" || var.network_acls_default_action == "Deny"
    error_message = "network_acls_default_action must be Allow or Deny."
  }
}

variable "network_acls_bypass" {
  type    = string
  default = "AzureServices"
}
variable "tags" { type = map(string) }
