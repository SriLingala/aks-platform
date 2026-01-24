project  = "portfolio"
env      = "dev"
location = "uksouth"

resource_group_name = "rg-portfolio-dev"
tenant_id           = "b58e8c48-dd94-4e31-9685-e1c0800dee58"

vnet_cidr           = "10.50.0.0/16"
aks_subnet_cidr     = "10.50.1.0/24"
bastion_subnet_cidr = "10.50.2.0/27"

kubernetes_version = "1.34.1"
system_node_count  = 2
system_vm_size     = "Standard_D2s_v3"
jumpbox_vm_size    = "Standard_D2s_v3"

jumpbox_admin_username = "azureuser"
jumpbox_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDy1q2a4YCr0mN3SRd4xrZMhdb0SbB0KIsmEmGZpNK1/6x+vsuFOwSBBmfouapDjJkk5V9lHZuaoWa3NBNem/FHqc6JW8sCVg5LWhbql2oTKxldGoGFGx/6k9wGNYYOwx4YJzJqlmsWVC9kpy1XKIYtfEpn+vd5FI1XBAq5BFqnTUIh/PDBPAxf/J5KN2gfpSkPiSrsGsKFpGRqQCW1a/YQNTaud4amVN44wmsYXQjMxUhKhqB6vNXx+aS815oa9gEWZZoGp15Jjb04bzSK5eYb4PuMHhnFk102Pqx41PoNFWBUOrAtB8wbXIMp1dt+M4zMQSjZWFHeJnOJT3H7ZdfQVU0cJKecFkYO9aYR6dgein0xHH/8TaizGaEN0Kwuv/5wrz+TsPmNriRgs7u6PIguyJuOoew0J0f0cxwwCRkpdgjEPvnov23pjW1y/t1lUbjiySNjgb7yO+ZpZD+N8zacfHRwwNb2pY4BwEBlq4RgSzmgcyoVntbs8q0pSmAlH78= Ramanjaneyulu@RAM-082018"

tags = {
  owner = "sri"
}
