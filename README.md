# AKS Platform Blueprint

> Production-grade Azure Kubernetes Service platform built with Terraform modules, Helm-based platform add-ons, and automated CI/CD via GitHub Actions.

[![Security Scan](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml/badge.svg)](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml)
[![tfsec](https://img.shields.io/badge/tfsec-enabled-5C4EE5?logo=terraform&logoColor=white)](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml)
[![Checkov](https://img.shields.io/badge/checkov-enabled-4CAF50?logo=paloaltonetworks&logoColor=white)](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml)
[![Falco](https://img.shields.io/badge/falco-runtime%20security-00ADEF?logoColor=white)](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml)

## Overview

This repository provisions a **private, security-hardened AKS cluster** on Azure with a full platform layer — networking, identity, secrets management, traffic routing, TLS, monitoring, and DNS — using reusable Terraform modules and Helm charts. It is designed as a reference blueprint for enterprise Kubernetes platforms.

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                  Azure Subscription / Virtual Network                  │
│                                                                        │
│  ┌────────────────┐  ┌──────────────────┐  ┌────────────────────────┐  │
│  │  VNet          │  │  Key Vault       │  │  User-Assigned         │  │
│  │  ├ AKS subnet  │  │  Purge protection│  │  Managed Identity      │  │
│  │  ├ Bastion sub │  │  Soft-delete 90d │  │  Workload ID           │  │
│  │  └ NSGs        │  │  Network ACLs    │  │  OIDC issuer           │  │
│  └────────────────┘  └──────────────────┘  └────────────────────────┘  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │        Private AKS cluster (API server: no public endpoint)      │  │
│  │                                                                  │  │
│  │  Node pools     System (AzureLinux, critical only) · User        │  │
│  │                                                                  │  │
│  │  Networking     Gateway API + Envoy Gateway (ingress-nginx       │  │
│  │                 retired Mar 2026) · Azure CNI · Network Policies │  │
│  │                 default deny · External DNS → Azure DNS          │  │
│  │                                                                  │  │
│  │  Platform       cert-manager (TLS) · Falco (eBPF runtime         │  │
│  │                 security)                                        │  │
│  │                                                                  │  │
│  │  Security       RBAC least privilege · Pod Security Standards    │  │
│  │                 (restricted app NS / baseline platform NS) ·     │  │
│  │                 AAD RBAC · local accounts disabled ·             │  │
│  │                 Defender for Containers (optional toggle)        │  │
│  │                                                                  │  │
│  │  Environment    dev (remote state: Azure Blob Storage)           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  CI/CD (GitHub Actions)                                          │  │
│  │  ├ terraform-validate   PR: fmt + init + validate + kubeconform  │  │
│  │  ├ security-pr-scan     PR: tfsec + Checkov + Falco lint         │  │
│  │  ├ terraform-plan       manual (needs live Azure subscription)   │  │
│  │  ├ terraform-apply      manual (needs live Azure subscription)   │  │
│  │  └ terraform-destroy    manual teardown                          │  │
│  │  Security findings → SARIF → GitHub Security tab                 │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌────────────────┐  (optional)                                       │
│  │  Jumpbox VM    │  Private access to AKS API via Azure Bastion      │
│  └────────────────┘                                                   │
└────────────────────────────────────────────────────────────────────────┘
```

## Key Features

| Area | Implementation |
|------|---------------|
| **Cluster** | Private AKS, Azure CNI, Azure network policy, AzureLinux OS |
| **Identity** | User-Assigned Managed Identity, Workload Identity, OIDC issuer |
| **RBAC** | Azure AD RBAC, local accounts disabled |
| **Secrets** | Azure Key Vault (RBAC authorisation, network ACLs, purge protection) |
| **Ingress** | Kubernetes Gateway API + Envoy Gateway ([ingress-nginx retired March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)) |
| **TLS** | cert-manager (Let's Encrypt ready) |
| **DNS** | External DNS with Azure DNS + Managed Identity |
| **Runtime Security** | Falco (eBPF); Microsoft Defender for Containers via opt-in toggle |
| **CI/CD** | GitHub Actions (validate + security scan on PR; plan/apply/destroy manual) |

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
│       └── dev/              # Development environment
├── platform/
│   ├── helm/
│   │   ├── cert-manager/           # TLS certificate automation
│   │   ├── gateway-api/            # Gateway API (Envoy Gateway) — replaces ingress-nginx
│   │   ├── external-dns/           # Automatic DNS record management
│   │   └── falco/                  # Runtime threat detection (eBPF)
│   └── manifests/
│       └── baseline/               # Namespaces (PSS labels), network policies, RBAC
├── scripts/
│   ├── install-platform.sh         # Automated platform add-on installer
│   └── reconcile-dev.sh            # Dev environment reconciliation
├── .github/workflows/
│   ├── security-pr-scan.yml        # tfsec + Checkov + Falco lint on every PR
│   ├── terraform-validate.yml      # Format check + validate + kubeconform
│   ├── terraform-plan.yml          # Plan (manual)
│   ├── terraform-apply.yml         # Apply (manual)
│   ├── terraform-bootstrap.yml     # Bootstrap remote state
│   ├── terraform-destroy.yml       # Tear down environment
│   └── terraform-destroy-bootstrap.yml
└── docs/
    ├── security-notes.md           # Full security architecture and control reference
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

## Security

[![Security Scan](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml/badge.svg)](https://github.com/SriLingala/aks-platform/actions/workflows/security-pr-scan.yml)

Every pull request triggers an automated security scan across Terraform and Kubernetes manifests before anything merges.

### Automated scanning on every PR

| Tool | Scope | What it catches |
|------|-------|----------------|
| **[tfsec](https://github.com/aquasecurity/tfsec)** | `terraform/` | Misconfigurations in Terraform — exposed storage, weak encryption, missing logging, insecure defaults |
| **[Checkov](https://github.com/bridgecrewio/checkov)** | `terraform/` + `platform/` | Policy violations across both IaC and Kubernetes manifests — covers CIS benchmarks |
| **[Falco lint](https://github.com/falcosecurity/falcoctl)** | `platform/helm/falco/` | Validates Falco rule files and all platform YAML before cluster apply |

Results are posted as a comment directly on the PR, updated on every new push — no need to leave GitHub to see findings:

```
## 🔐 Security Scan Results
✅ All security checks passed
────────────────────────────────────
tfsec — ✅ PASSED
| Severity  | Count |
| Critical  |   0   |
| High      |   0   |
────────────────────────────────────
Checkov — ✅ PASSED
| Passed  | Failed | Skipped |
|   47    |    0   |    2    |
────────────────────────────────────
Falco rule lint — ✅ PASSED
```

SARIF results are also uploaded to the **[Security tab](https://github.com/SriLingala/aks-platform/security/code-scanning)** for a persistent view of findings across branches.

### Security architecture (5 layers)

```
Layer 5 — Runtime          Falco (eBPF); Microsoft Defender for Containers (opt-in)
Layer 4 — Workload         Pod Security Standards (enforce: restricted on app namespaces)
                           Kubernetes RBAC (platform-viewer / app-developer / namespace-admin)
                           Workload Identity — no secrets stored in pods
Layer 3 — Network          Network Policies — default deny-all, selective allow
                           Private AKS cluster — API server off the internet
                           Azure Bastion — no public SSH/RDP
Layer 2 — Identity         AAD RBAC, local accounts disabled
                           Key Vault RBAC authorisation
                           User-Assigned Managed Identity
Layer 1 — Infrastructure   tfsec + Checkov scanning in CI
                           Secure-by-default Terraform variable values
                           Key Vault purge protection + 90-day soft delete
                           TLS-only remote state storage
```

See [docs/security-notes.md](docs/security-notes.md) for the full control reference, RBAC model, and known gaps.

## CI/CD

GitHub Actions workflows handle the full lifecycle:

| Workflow | Trigger | Action |
|----------|---------|--------|
| `security-pr-scan` | **Every PR** | tfsec + Checkov + Falco lint → PR comment |
| `terraform-validate` | PR | Format check + validate + kubeconform |
| `terraform-plan` | Manual | Terraform plan (needs a live Azure subscription via repo secrets) |
| `terraform-apply` | Manual | Apply changes (needs a live Azure subscription via repo secrets) |
| `terraform-destroy` | Manual | Tear down environment |
| `terraform-bootstrap` | Manual | Provision remote state backend |

## Tech Stack

- **Cloud**: Microsoft Azure
- **IaC**: Terraform (modular, multi-environment)
- **Container Orchestration**: Azure Kubernetes Service (AKS)
- **CI/CD**: GitHub Actions
- **Security scanning**: tfsec, Checkov
- **Runtime security**: Falco (eBPF); Microsoft Defender for Containers (opt-in)
- **Ingress**: Kubernetes Gateway API + Envoy Gateway (ingress-nginx retired March 2026)
- **TLS**: cert-manager
- **DNS**: External DNS
- **Secrets**: Azure Key Vault
- **Identity**: Azure AD, Workload Identity, Managed Identity
- **Scripting**: Bash
