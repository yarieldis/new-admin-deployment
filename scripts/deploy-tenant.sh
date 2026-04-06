#!/bin/bash
# Deploy or upgrade a tenant
# Usage: ./scripts/deploy-tenant.sh <tenant-name>
# Example: ./scripts/deploy-tenant.sh tanzania
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TENANT_NAME="${1:?Usage: deploy-tenant.sh <tenant-name>}"
VALUES_FILE="$PROJECT_ROOT/tenants/${TENANT_NAME}.yaml"

if [ ! -f "$VALUES_FILE" ]; then
  echo "ERROR: Tenant values file not found: $VALUES_FILE"
  echo "       Create it first (see tenants/example-tenant.yaml)."
  exit 1
fi

echo "==> Deploying tenant: $TENANT_NAME"
helm upgrade --install "$TENANT_NAME" "$PROJECT_ROOT/helm/eregulations" \
  --namespace "$TENANT_NAME" \
  --create-namespace \
  -f "$VALUES_FILE"

echo ""
echo "==> Waiting for rollout..."
minikube kubectl -- -n "$TENANT_NAME" rollout status deployment/"$TENANT_NAME"-webapi --timeout=90s
minikube kubectl -- -n "$TENANT_NAME" rollout status deployment/"$TENANT_NAME"-spa --timeout=90s

echo ""
echo "==> Tenant '$TENANT_NAME' is deployed."
echo "    Add to hosts file: $(minikube ip)  ${TENANT_NAME}.local"
