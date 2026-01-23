locals {
  name_prefix = "${var.project}-${var.env}"
  tags = merge(var.tags, {
    project = var.project
    env     = var.env
  })
}

module "bootstrap" {
  source                      = "../../modules/bootstrap"
  name_prefix                 = local.name_prefix
  location                    = var.location
  resource_group_name         = var.resource_group_name
  storage_account_name_prefix = var.storage_account_name_prefix
  container_name              = var.container_name
  tags                        = local.tags
}
