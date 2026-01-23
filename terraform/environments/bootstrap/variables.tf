variable "project" { type = string }
variable "env" { type = string }
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

variable "tags" {
  type    = map(string)
  default = {}
}
