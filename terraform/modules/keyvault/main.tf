resource "azurerm_key_vault" "kv" {
  name                       = replace("${var.name_prefix}-kv", "-", "")
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  tags                       = var.tags
}
