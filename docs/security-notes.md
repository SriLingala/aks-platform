# Security Architecture

This document covers the security controls implemented in this platform, why each one exists, and what gaps remain.

---

## Layers of Defence

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 5 — Runtime               Falco (eBPF)               │
├─────────────────────────────────────────────────────────────┤
│  Layer 4 — Workload              Pod Security Standards      │
│                                  Kubernetes RBAC             │
│                                  Workload Identity (no keys) │
├─────────────────────────────────────────────────────────────┤
│  Layer 3 — Network               Network Policies (zero-trust│
│                                  deny-all + selective allow) │
│                                  Private AKS cluster         │
│                                  Azure Bastion (no SSH/RDP)  │
├─────────────────────────────────────────────────────────────┤
│  Layer 2 — Identity & Access     AAD RBAC, local accts off   │
│                                  Key Vault RBAC auth         │
│                                  Managed Identity            │
├─────────────────────────────────────────────────────────────┤
│  Layer 1 — Infrastructure        Terraform (IaC, no drift)   │
│                                  tfsec + Checkov CI scanning │
│                                  Private endpoints           │
│                                  Purge protection, soft delete│
└─────────────────────────────────────────────────────────────┘
```

---

## Controls Implemented

### Identity & Access

| Control | Implementation | Why |
|---------|---------------|-----|
| No local Kubernetes accounts | `local_account_disabled = true` | Forces all access through AAD — no shared credentials |
| Azure AD RBAC | `azure_rbac_enabled = true` | Maps AAD groups to Kubernetes roles — audit trail in AAD |
| Workload Identity | OIDC + federated credentials | Pods authenticate to Azure without any stored secrets or keys |
| Key Vault RBAC | `enable_rbac_authorization = true` | Replaces legacy access policies — granular, auditable |
| Managed Identity | User-assigned identity for AKS | No service principal secrets to rotate or leak |

### Network

| Control | Implementation | Why |
|---------|---------------|-----|
| Private cluster | `private_cluster_enabled = true` | AKS API server not reachable from internet |
| Azure Bastion | Bastion subnet + host in network module | SSH/RDP to nodes without exposing public IPs |
| Network Policies | `networkpolicies.yaml` — deny-all default | Zero-trust pod-to-pod traffic — teams cannot talk to each other by default |
| Network plugin | Azure CNI | Required for Network Policy enforcement |
| API server IP restriction | `api_server_authorized_ip_ranges` | Optional — further restricts who can reach the API |

### Workload Security

| Control | Implementation | Why |
|---------|---------------|-----|
| Pod Security Standards | Namespace labels — `enforce: restricted` on app namespaces | Blocks root containers, privilege escalation, host mounts |
| System node isolation | `only_critical_addons_enabled = true` | App workloads cannot schedule on system node pool |
| Image Cleaner | `image_cleaner_enabled = true`, 48h interval | Removes unused/vulnerable images from nodes automatically |
| Secrets via CSI | Key Vault CSI driver | Secrets never stored in Kubernetes — mounted from Key Vault at pod start |

### Runtime Threat Detection

| Control | Implementation | Why |
|---------|---------------|-----|
| Falco | `platform/helm/falco/values.yaml` | Detects unexpected syscalls, privilege escalation, container escapes at runtime |
| eBPF driver | `driver.kind: modern_ebpf` | No kernel module needed — works on AzureLinux, lower attack surface |
| falcosidekick | Enabled, Azure Monitor integration | Forwards Falco alerts to Log Analytics for centralised alerting |
| Microsoft Defender for Containers | AKS `microsoft_defender` block | Vulnerability scanning, anomaly detection, regulatory compliance posture |

### IaC & Supply Chain

| Control | Implementation | Why |
|---------|---------------|-----|
| tfsec | CI pipeline — `security-scan` job | Catches Terraform misconfigurations before apply |
| Checkov | CI pipeline — `security-scan` job | Scans both Terraform and Kubernetes manifests |
| SARIF upload | GitHub Security tab integration | Findings visible in PRs and Security overview |
| kubeconform | CI `manifest-lint` job | Validates manifest schema before cluster apply |
| Purge protection | Key Vault `purge_protection_enabled = true` | Prevents accidental/malicious permanent deletion |
| Soft delete | Key Vault `soft_delete_retention_days = 90` | 90-day recovery window |
| TLS-only state storage | Bootstrap module | Terraform state cannot be fetched over HTTP |

---

## RBAC Model

Three roles, scoped by least privilege:

```
platform-viewer    → ClusterRoleBinding → Prometheus service account
app-developer      → RoleBinding        → namespace only (team-a-developers AAD group)
namespace-admin    → RoleBinding        → namespace only (team-a-leads AAD group)
```

No team can grant themselves additional permissions. No secrets access via Kubernetes — all secrets come through Key Vault CSI.

---

## What's Not Implemented (Known Gaps)

| Gap | Reason | Recommended approach |
|-----|--------|----------------------|
| Private endpoints for Key Vault | Adds cost, out of scope for portfolio | `azurerm_private_endpoint` + private DNS zone |
| OPA/Gatekeeper constraint policies | Azure Policy add-on covers basics | Add `ConstraintTemplate` CRDs for custom rules |
| Image signing/verification | Requires registry setup | Notary v2 + Azure Container Registry |
| Secrets rotation automation | No ACR or external secrets operator | External Secrets Operator + Key Vault rotation policy |
| mTLS between services | No service mesh in scope | Istio or Azure Service Mesh with PeerAuthentication |

---

## Hardening for Production

Minimum additional steps before production:

1. Set `aad_admin_group_object_ids` — no anonymous cluster admin
2. Set `public_network_access_enabled = false` on both AKS and Key Vault
3. Set Key Vault `network_acls` to deny public and allow only private endpoint
4. Pin all module versions — no floating `latest`
5. Enable diagnostic settings on AKS → Log Analytics
6. Set Falco `falcosidekick.config.azure.workspaceId` from Key Vault

---

## Pre-merge Security Checklist

Every PR that touches `terraform/` or `platform/` must pass the automated security gate:

- [ ] tfsec — zero HIGH or CRITICAL findings
- [ ] Checkov — zero failed checks (skipped checks must be justified in code comments)
- [ ] Falco lint — all YAML files valid, required keys present
- [ ] No secrets or credentials committed (checked by `.gitignore` and pre-commit hooks)
- [ ] Terraform variable defaults remain secure (`public_network_access_enabled = false`, `local_account_disabled = true`)

Results are posted automatically as a PR comment by the `security-pr-scan` workflow.
See [`.github/workflows/security-pr-scan.yml`](../.github/workflows/security-pr-scan.yml).
