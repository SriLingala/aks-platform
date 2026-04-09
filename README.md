# AKS Platform Blueprint

> Production-grade Azure Kubernetes Service platform built with Terraform modules, Helm-based platform add-ons, and automated CI/CD via GitHub Actions.

## Overview

This repository provisions a **private, security-hardened AKS cluster** on Azure with a full platform layer — networking, identity, secrets management, ingress, TLS, monitoring, and DNS — using reusable Terraform modules and Helm charts. It is designed as a reference blueprint for enterprise Kubernetes platforms.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Azure Subscription                   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   VNet        │  │   Key Vault  │  │  User-Assigned│  │
│  │  ├─ AKS Subnet│  │  (CSI-backed)│  │  Managed ID   │  │
│  │  └─ Bastion   │  └──────────────┘  └──────────────┘  │
│  └──────────────┘                                        │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │        Private AKS Cluster                        │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │    │
│  │  │Ingress   │ │Cert      │ │Kube Prometheus   │  │    │
│  │  │NGINX     │ │Manager   │ │Stack (Monitoring)│  │    │
│  │  └──────────┘ └──────────┘ └──────────────────┘  │    │
│  │  ┌──────────┐ ┌──────────────────────────────┐   │    │
│  │  │External  │ │CSI Secrets Store (KeyVault)   │   │    │
│  │  │DNS       │ │+ Workload Identity            │   │    │
│  │  └──────────┘ └──────────────────────────────┘   │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  ┌──────────────┐  (optional)                            │
│  │  Jumpbox VM   │                                       │
│  └──────────────┘                                        │
└─────────────────────────────────────────────────────────┘
```

## Key Features

| Area | Implementation |
|------|---------------|
| **Cluster** | Private AKS, Azure CNI, Azure network policy, AzureLinux OS |
| **Identity** | User-Assigned Managed Identity, Workload Identity, OIDC issuer |
| **RBAC** | Azure AD RBAC, local accounts disabled |
| **Secrets** | Azure Key Vault + CSI Secrets Store driver |
| **Ingress** | NGINX Ingress Controller |
| **TLS** | cert-manager (Let's Encrypt ready) |
| **Monitoring** | kube-prometheus-stack (Prometheus, Grafana, Alertmanager) |
| **DNS** | External DNS with Azure DNS + Managed Identity |
| **Security** | Azure Policy add-on, network policies, private endpoint ready |
| **CI/CD** | GitHub Actions (validate, plan, apply, destroy) + Azure DevOps pipeline |

## Repository Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── aks/              # AKS cluster with private API, RBAC, Workload Identity
│   │   ├── network/          # VNet, subnets (AKS + Bastion), NSGs
│   │   ├── identity/         # User-Assigned Managed Identity for AKS
│   │   ├── keyvault/         # Key Vault with soft-delete, purge protection
│   │   ├── jumpbox/          # Optional VM for private cluster access
│   │   └── bootstrap/        # Remote state backend (Storage Account)
│   └── environments/
│       ├── bootstrap/        # State storage provisioning
│       ├── dev/              # Development environment
│       └── prod/             # Production environment
├── platform/
│   ├── helm/
│   │   ├── cert-manager/           # TLS certificate automation
│   │   ├── ingress-nginx/          # Ingress controller
│   │   ├── kube-prometheus-stack/  # Full observability stack
│   │   ├── external-dns/           # Automatic DNS record management
│   │   └── csi-secrets-store/      # Azure Key Vault integration
│   └── manifests/
│       ├── baseline/               # Namespaces, network policies
│       ├── keyvault-csi-demo/      # Secrets Store CSI demo
│       └── workload-identity-demo/ # Workload Identity demo
├── scripts/
│   ├── install-platform.sh         # Automated platform add-on installer
│   └── reconcile-dev.sh            # Dev environment reconciliation
├── pipelines/
│   └── azure-devops/               # Azure DevOps pipeline definition
├── .github/workflows/
│   ├── terraform-validate.yml
│   ├── terraform-plan.yml
│   ├── terraform-apply.yml
│   ├── terraform-bootstrap.yml
│   ├── terraform-destroy.yml
│   └── terraform-destroy-bootstrap.yml
└── docs/
    ├── architecture.md
    ├── decisions.md
    ├── security-notes.md
    ├── cost-notes.md
    └── runbook.md
```

## Getting Started

### Prerequisites

- Azure CLI (`az`) with an active subscription
- Terraform >= 1.5
- Helm >= 3.12
- `kubectl`

### 1. Bootstrap Remote State

```bash
cd terraform/environments/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform apply
```

### 2. Deploy the Platform Infrastructure

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform apply
```

### 3. Install Platform Add-Ons

```bash
AKS_RESOURCE_GROUP=rg-portfolio-dev \
AKS_NAME=portfolio-dev-aks \
bash scripts/install-platform.sh
```

See the [runbook](docs/runbook.md) for External DNS configuration and advanced options.

## Security Posture

- Private cluster API server (public access disabled by default)
- Azure AD RBAC with local accounts disabled
- Azure Policy add-on enforces guardrails
- Key Vault with soft-delete and purge protection
- Network policies applied at baseline
- Workload Identity for pod-level Azure access (no stored secrets)
- TLS-only state storage with Azure AD auth

See [security-notes.md](docs/security-notes.md) for the full security baseline.

## CI/CD

GitHub Actions workflows handle the full lifecycle:

| Workflow | Trigger | Action |
|----------|---------|--------|
| `terraform-validate` | PR | Format check + validate |
| `terraform-plan` | PR | Plan with diff comment |
| `terraform-apply` | Merge to main | Apply changes |
| `terraform-destroy` | Manual | Tear down environment |

An Azure DevOps pipeline (`pipelines/azure-devops/azure-pipelines.yml`) is also provided for teams using ADO.

## Tech Stack

- **Cloud**: Microsoft Azure
- **IaC**: Terraform (modular, multi-environment)
- **Container Orchestration**: Azure Kubernetes Service (AKS)
- **CI/CD**: GitHub Actions, Azure DevOps
- **Monitoring**: Prometheus, Grafana, Alertmanager (kube-prometheus-stack)
- **Ingress**: NGINX Ingress Controller
- **TLS**: cert-manager
- **DNS**: External DNS
- **Secrets**: Azure Key Vault + CSI Secrets Store
- **Identity**: Azure AD, Workload Identity, Managed Identity
- **Scripting**: Bash

## License

[MIT](LICENSE)
