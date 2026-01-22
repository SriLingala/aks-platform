output "aks_uami_id" {
  value = azurerm_user_assigned_identity.aks.id
}

output "aks_uami_client_id" {
  value = azurerm_user_assigned_identity.aks.client_id
}
