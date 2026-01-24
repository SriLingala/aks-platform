#!/usr/bin/env bash
set -euo pipefail

TF_DIR="terraform/environments/dev"
TFVARS="${TF_DIR}/terraform.tfvars"

if [[ ! -f "${TFVARS}" ]]; then
  if [[ -f "${TF_DIR}/terraform.tfvars.example" ]]; then
    cp "${TF_DIR}/terraform.tfvars.example" "${TFVARS}"
  else
    echo "Missing ${TFVARS} and terraform.tfvars.example." >&2
    exit 1
  fi
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required for reconcile step." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Azure CLI not logged in. Run az login or use azure/login in CI." >&2
  exit 1
fi

get_var() {
  local key="$1"
  local value
  value=$(grep -E "^${key}[[:space:]]*=" "${TFVARS}" | head -n1 | awk -F'"' '{print $2}')
  if [[ -z "${value}" ]]; then
    echo "Missing ${key} in ${TFVARS}." >&2
    exit 1
  fi
  echo "${value}"
}

PROJECT="$(get_var project)"
ENVIRONMENT="$(get_var env)"
RESOURCE_GROUP="$(get_var resource_group_name)"
SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:?ARM_SUBSCRIPTION_ID is required}"

NAME_PREFIX="${PROJECT}-${ENVIRONMENT}"

import_if_exists() {
  local address="$1"
  local id="$2"

  if terraform -chdir="${TF_DIR}" state list | grep -q "^${address}$"; then
    echo "State already has ${address}"
    return
  fi

  if az resource show --ids "${id}" >/dev/null 2>&1; then
    terraform -chdir="${TF_DIR}" import "${address}" "${id}"
  else
    echo "Resource not found, skipping import: ${id}"
  fi
}

import_if_exists \
  "module.network.azurerm_resource_group.rg" \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"

import_if_exists \
  "module.network.azurerm_virtual_network.vnet" \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${NAME_PREFIX}-vnet"

import_if_exists \
  "module.network.azurerm_public_ip.bastion" \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/publicIPAddresses/${NAME_PREFIX}-bastion-pip"

import_if_exists \
  "module.network.azurerm_subnet.aks" \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${NAME_PREFIX}-vnet/subnets/${NAME_PREFIX}-aks-subnet"

import_if_exists \
  "module.network.azurerm_subnet.bastion" \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${NAME_PREFIX}-vnet/subnets/AzureBastionSubnet"

import_if_exists \
  "module.network.azurerm_bastion_host.bastion" \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/bastionHosts/${NAME_PREFIX}-bastion"
