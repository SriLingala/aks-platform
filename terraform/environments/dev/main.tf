locals {
  name_prefix = "${var.project}-${var.env}"
  tags = merge(var.tags, {
    project = var.project
    env     = var.env
  })
}

module "jumpbox" {
  count               = var.enable_jumpbox ? 1 : 0
  source              = "../../modules/jumpbox"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  # put jumpbox into same subnet for simplicity (ok for portfolio)
  subnet_id = module.network.aks_subnet_id

  vm_size        = var.jumpbox_vm_size
  admin_username = var.jumpbox_admin_username
  ssh_public_key = var.jumpbox_ssh_public_key
  tags           = local.tags
}

module "network" {
  source              = "../../modules/network"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  vnet_cidr           = var.vnet_cidr
  aks_subnet_cidr     = var.aks_subnet_cidr
  bastion_subnet_cidr = var.bastion_subnet_cidr
  tags                = local.tags
}

module "identity" {
  source              = "../../modules/identity"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  depends_on          = [module.network]
}

module "keyvault" {
  source              = "../../modules/keyvault"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  public_network_access_enabled = var.keyvault_public_network_access_enabled
  purge_protection_enabled       = var.keyvault_purge_protection_enabled
  soft_delete_retention_days     = var.keyvault_soft_delete_retention_days
  enable_network_acls            = var.keyvault_enable_network_acls
  network_acls_default_action    = var.keyvault_network_acls_default_action
  network_acls_bypass            = var.keyvault_network_acls_bypass
  tags                = local.tags
  depends_on          = [module.network]
}

module "aks" {
  source              = "../../modules/aks"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id       = module.network.aks_subnet_id
  aks_identity_id = module.identity.aks_uami_id

  kubernetes_version = var.kubernetes_version
  system_node_count  = var.system_node_count
  system_vm_size     = var.system_vm_size
  public_network_access_enabled = var.public_network_access_enabled
  local_account_disabled         = var.local_account_disabled
  azure_policy_enabled           = var.azure_policy_enabled
  enable_aad_rbac                = var.enable_aad_rbac
  aad_admin_group_object_ids     = var.aad_admin_group_object_ids
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  outbound_type                  = var.outbound_type
  load_balancer_sku              = var.load_balancer_sku

  tags = local.tags
}

resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  scope                = module.network.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.identity.aks_uami_principal_id
}

output "aks_name" {
  value = module.aks.aks_name
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}
