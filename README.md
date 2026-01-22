# AKS Platform Starter (Terraform + GitOps-friendly)

A production-ready baseline for Azure Kubernetes Service (AKS) built with Terraform.
Includes Workload Identity, Key Vault CSI integration, ingress, TLS automation, DNS automation, and an extensible platform layer.

## What you get
- AKS cluster with private networking ready patterns
- Managed identities + Workload Identity (OIDC issuer enabled)
- Key Vault + CSI Secrets Store (pod consumes secrets without storing in Kubernetes)
- Ingress NGINX (swap later for Gateway API / AGC if needed)
- cert-manager for TLS
- ExternalDNS for automated DNS records
- Optional: kube-prometheus-stack hook for observability

## Architecture (high level)
- Terraform provisions: RG, VNet/Subnets, AKS, identities, Key Vault, role assignments
- Platform layer installs baseline add-ons via Helm values
- Demo manifests validate Workload Identity and Key Vault secret retrieval

## Prerequisites
- Azure subscription access
- Azure CLI logged in: `az login`
- Terraform >= 1.6
- kubectl + helm

## Quickstart (Dev)
1. Configure variables:
   - Copy: `terraform/environments/dev/terraform.tfvars.example` to `terraform.tfvars`
2. Deploy infra:
   - `cd terraform/environments/dev`
   - `terraform init`
   - `terraform plan`
   - `terraform apply`
3. Get kubeconfig:
   - `az aks get-credentials -g <rg> -n <aks-name> --admin`
4. Install platform add-ons (example order):
   - cert-manager
   - csi-secrets-store
   - external-dns
   - ingress-nginx
5. Run demos:
   - Workload Identity demo
   - Key Vault CSI demo

## Security notes
- Uses managed identity and OIDC federation for workload identity
- Key Vault access via RBAC and least privilege
- No secrets stored in Terraform state (use Key Vault references and CSI)

## Cost notes
- Biggest cost drivers: node pools, NAT gateway, load balancers, logs
- Start with small node pool sizes in dev

## Cleanup
- `terraform destroy` from the environment folder
