#!/bin/bash
# Initial minikube setup for eRegulations
# Usage: ./scripts/setup-minikube.sh
set -euo pipefail

echo "==> Starting minikube with Podman driver..."
minikube start --driver=podman --memory=4096 --cpus=2

echo "==> Enabling ingress addon..."
minikube addons enable ingress

echo "==> Deploying infrastructure (MSSQL)..."
minikube kubectl -- apply -f infrastructure/

echo "==> Waiting for MSSQL to be ready..."
minikube kubectl -- -n infrastructure rollout status statefulset/mssql --timeout=120s

echo ""
echo "==> Minikube is ready."
echo "    MSSQL is running in the 'infrastructure' namespace."
echo ""
echo "    Next steps:"
echo "      1. Build images:  ./scripts/build-images.sh"
echo "      2. Deploy tenant: ./scripts/deploy-tenant.sh tanzania"
echo ""
echo "    Minikube IP: $(minikube ip)"
