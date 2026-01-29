terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_string" "kv_suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  keyvault_name = substr(
    replace(lower("${var.name_prefix}kv${random_string.kv_suffix.result}"), "-", ""),
    0,
    24
  )
}

resource "azurerm_key_vault" "kv" {
  name                       = local.keyvault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days
  enable_rbac_authorization  = true
  public_network_access_enabled = var.public_network_access_enabled
  tags                       = var.tags

  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      default_action = var.network_acls_default_action
      bypass         = var.network_acls_bypass
    }
  }
}
