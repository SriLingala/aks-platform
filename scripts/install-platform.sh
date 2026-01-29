#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd az
require_cmd helm

AKS_RESOURCE_GROUP="${AKS_RESOURCE_GROUP:-rg-portfolio-dev}"
AKS_NAME="${AKS_NAME:-portfolio-dev-aks}"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

helm repo add jetstack https://charts.jetstack.io >/dev/null
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ >/dev/null
helm repo update >/dev/null

aks_kubectl() {
  az aks command invoke \
    --resource-group "$AKS_RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --command "$1" >/dev/null
}

apply_manifest() {
  local release="$1"
  local chart="$2"
  local namespace="$3"
  local values_file="$4"
  shift 4
  local manifest="$TMP_DIR/${release}.yaml"

  helm template "$release" "$chart" \
    --namespace "$namespace" \
    -f "$values_file" \
    "$@" > "$manifest"

  aks_kubectl "kubectl get ns $namespace >/dev/null 2>&1 || kubectl create ns $namespace"

  az aks command invoke \
    --resource-group "$AKS_RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --command "kubectl apply -f ${release}.yaml" \
    --file "$manifest" >/dev/null
}

apply_manifest \
  "cert-manager" \
  "jetstack/cert-manager" \
  "cert-manager" \
  "$ROOT_DIR/platform/helm/cert-manager/values.yaml" \
  --set installCRDs=true

apply_manifest \
  "ingress-nginx" \
  "ingress-nginx/ingress-nginx" \
  "ingress-nginx" \
  "$ROOT_DIR/platform/helm/ingress-nginx/values.yaml"

if [[ "${ENABLE_EXTERNAL_DNS:-false}" == "true" ]]; then
  if [[ -z "${EXTERNAL_DNS_RESOURCE_GROUP:-}" || -z "${EXTERNAL_DNS_SUBSCRIPTION_ID:-}" || -z "${EXTERNAL_DNS_TENANT_ID:-}" || -z "${EXTERNAL_DNS_DOMAIN_FILTERS:-}" ]]; then
    echo "external-dns enabled but missing config. Set EXTERNAL_DNS_RESOURCE_GROUP, EXTERNAL_DNS_SUBSCRIPTION_ID, EXTERNAL_DNS_TENANT_ID, EXTERNAL_DNS_DOMAIN_FILTERS." >&2
    exit 1
  fi

  extra_args=(
    --set provider=azure
    --set "azure.resourceGroup=${EXTERNAL_DNS_RESOURCE_GROUP}"
    --set "azure.subscriptionId=${EXTERNAL_DNS_SUBSCRIPTION_ID}"
    --set "azure.tenantId=${EXTERNAL_DNS_TENANT_ID}"
    --set registry=txt
    --set "txtOwnerId=${EXTERNAL_DNS_TXT_OWNER_ID:-aks-platform-dev}"
  )

  IFS=',' read -r -a domains <<< "$EXTERNAL_DNS_DOMAIN_FILTERS"
  for i in "${!domains[@]}"; do
    extra_args+=(--set "domainFilters[${i}]=${domains[$i]}")
  done

  if [[ "${EXTERNAL_DNS_USE_MANAGED_IDENTITY:-false}" == "true" ]]; then
    extra_args+=(--set azure.useManagedIdentityExtension=true)
    if [[ -n "${EXTERNAL_DNS_USER_ASSIGNED_IDENTITY_ID:-}" ]]; then
      extra_args+=(--set "azure.userAssignedIdentityID=${EXTERNAL_DNS_USER_ASSIGNED_IDENTITY_ID}")
    fi
  else
    echo "external-dns requires managed identity config. Set EXTERNAL_DNS_USE_MANAGED_IDENTITY=true (and EXTERNAL_DNS_USER_ASSIGNED_IDENTITY_ID if using a UAMI)." >&2
    exit 1
  fi

  apply_manifest \
    "external-dns" \
    "external-dns/external-dns" \
    "external-dns" \
    "$ROOT_DIR/platform/helm/external-dns/values.yaml" \
    "${extra_args[@]}"
else
  echo "Skipping external-dns. Set ENABLE_EXTERNAL_DNS=true and required EXTERNAL_DNS_* vars to enable." >&2
fi

echo "Platform components applied."
