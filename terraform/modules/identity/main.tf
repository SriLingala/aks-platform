resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.name_prefix}-aks-uami"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
