## Security baseline

- Prefer private cluster API and disable public network access.
- Use Azure AD RBAC for AKS and disable local accounts.
- Enable Azure Policy add-on for AKS.
- Restrict Key Vault public access once private endpoints are in place.
- Enable purge protection and increase soft delete retention in production.
- Lock down state storage: TLS-only, no public blob access, prefer Azure AD auth.

## Required inputs for hardened mode

- AKS AAD admin group object IDs (`aad_admin_group_object_ids`).
- Private DNS + private endpoints for Key Vault and state storage.
