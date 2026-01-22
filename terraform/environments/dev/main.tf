locals {
  name_prefix = "${var.project}-${var.env}"
  tags = merge(var.tags, {
    project = var.project
    env     = var.env
  })
}

module "jumpbox" {
  source              = "../../modules/jumpbox"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  # put jumpbox into same subnet for simplicity (ok for portfolio)
  subnet_id           = module.network.aks_subnet_id

  vm_size             = "Standard_B2s"
  admin_username      = var.jumpbox_admin_username
  ssh_public_key      = var.jumpbox_ssh_public_key
  tags                = local.tags
}

module "network" {
  source              = "../../modules/network"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  vnet_cidr           = var.vnet_cidr
  aks_subnet_cidr     = var.aks_subnet_cidr
  tags                = local.tags
}

module "identity" {
  source              = "../../modules/identity"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

module "keyvault" {
  source              = "../../modules/keyvault"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  tags                = local.tags
}

module "aks" {
  source              = "../../modules/aks"
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id           = module.network.aks_subnet_id
  aks_identity_id     = module.identity.aks_uami_id

  kubernetes_version  = var.kubernetes_version
  system_node_count   = var.system_node_count
  system_vm_size      = var.system_vm_size

  tags                = local.tags
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
