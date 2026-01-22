resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.name_prefix}-dns"

  # Private cluster
  private_cluster_enabled = true

  # Use AKS-managed private DNS zone (simplest for portfolio)
  private_dns_zone_id = "System"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [var.aks_identity_id]
  }

  default_node_pool {
    name           = "system"
    node_count     = var.system_node_count
    vm_size        = var.system_vm_size
    vnet_subnet_id = var.subnet_id
    os_sku         = "AzureLinux"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    outbound_type  = "loadBalancer"
  }

  kubernetes_version = var.kubernetes_version
  tags               = var.tags
}
