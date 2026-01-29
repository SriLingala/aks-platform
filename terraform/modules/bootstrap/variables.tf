variable "name_prefix" { type = string }
variable "location" { type = string }

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "storage_account_name_prefix" {
  type    = string
  default = ""
}

variable "container_name" {
  type    = string
  default = "tfstate"
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "shared_access_key_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.name_prefix}-tfstate"
  sa_prefix           = var.storage_account_name_prefix != "" ? var.storage_account_name_prefix : var.name_prefix
  storage_account_name = substr(
    replace(lower("${local.sa_prefix}tf${random_string.suffix.result}"), "-", ""),
    0,
    24
  )
}
