resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.name_prefix}-dns"

  # Private cluster — API server not exposed to internet
  private_cluster_enabled       = true
  public_network_access_enabled = var.public_network_access_enabled

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
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aad_admin_group_object_ids
    }
  }

  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    vm_size                      = var.system_vm_size
    vnet_subnet_id               = var.subnet_id
    os_sku                       = "AzureLinux"
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    outbound_type     = var.outbound_type
    load_balancer_sku = var.load_balancer_sku
  }

  # Microsoft Defender for Containers — runtime threat detection
  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Image cleaner — removes unused/vulnerable images from nodes
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  # Storage profile — disable deprecated blob driver, enable snapshot controller
  storage_profile {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  # Maintenance window — control when node OS patches apply
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    utc_offset  = "+00:00"
    start_time  = "02:00"
  }

  kubernetes_version = var.kubernetes_version
  tags               = var.tags
}
