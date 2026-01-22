output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "bastion_host_id" {
  value = azurerm_bastion_host.bastion.id
}
