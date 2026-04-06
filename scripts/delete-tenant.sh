#!/bin/bash
# Delete a tenant and its namespace
# Usage: ./scripts/delete-tenant.sh <tenant-name>
set -euo pipefail

TENANT_NAME="${1:?Usage: delete-tenant.sh <tenant-name>}"

echo "==> Uninstalling Helm release: $TENANT_NAME"
helm uninstall "$TENANT_NAME" --namespace "$TENANT_NAME"

echo "==> Deleting namespace: $TENANT_NAME"
minikube kubectl -- delete namespace "$TENANT_NAME"

echo "==> Tenant '$TENANT_NAME' removed."
