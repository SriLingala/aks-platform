## Install platform add-ons

Run from a machine that has Azure CLI and Helm installed:

```bash
AKS_RESOURCE_GROUP=rg-portfolio-dev \
AKS_NAME=portfolio-dev-aks \
bash scripts/install-platform.sh
```

To enable external-dns (Azure DNS with managed identity), set:

```bash
ENABLE_EXTERNAL_DNS=true \
EXTERNAL_DNS_RESOURCE_GROUP=<dns-rg> \
EXTERNAL_DNS_SUBSCRIPTION_ID=<sub-id> \
EXTERNAL_DNS_TENANT_ID=<tenant-id> \
EXTERNAL_DNS_DOMAIN_FILTERS=example.com \
EXTERNAL_DNS_USE_MANAGED_IDENTITY=true \
EXTERNAL_DNS_USER_ASSIGNED_IDENTITY_ID=<uami-resource-id> \
bash scripts/install-platform.sh
```
