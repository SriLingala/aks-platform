resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.name_prefix}-dns"

  # Private cluster
  private_cluster_enabled = true
  public_network_access_enabled = var.public_network_access_enabled

  # Use AKS-managed private DNS zone (simplest for portfolio)
  private_dns_zone_id = "System"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = var.azure_policy_enabled
  local_account_disabled    = var.local_account_disabled

  identity {
    type         = "UserAssigned"
    identity_ids = [var.aks_identity_id]
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_aad_rbac ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled      = true
      admin_group_object_ids = var.aad_admin_group_object_ids
    }
  }

  default_node_pool {
    name           = "system"
    node_count     = var.system_node_count
    vm_size        = var.system_vm_size
    vnet_subnet_id = var.subnet_id
    os_sku         = "AzureLinux"
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    outbound_type  = var.outbound_type
    load_balancer_sku = var.load_balancer_sku
  }

  kubernetes_version = var.kubernetes_version
  tags               = var.tags
}
