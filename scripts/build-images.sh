#!/bin/bash
# Build container images inside minikube's Podman daemon
# Usage: ./scripts/build-images.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SPA_CONTEXT="$PROJECT_ROOT/../angular/eregulations-5.0-admin-spa"
WEBAPI_CONTEXT="$PROJECT_ROOT/../eregulations-net8/eregulations-4.0-admin-api/Project"

# Verify source repos exist
if [ ! -d "$SPA_CONTEXT" ]; then
  echo "ERROR: SPA source not found at $SPA_CONTEXT"
  echo "       Clone the Angular repo as a sibling directory."
  exit 1
fi

if [ ! -d "$WEBAPI_CONTEXT" ]; then
  echo "ERROR: WebAPI source not found at $WEBAPI_CONTEXT"
  echo "       Clone the .NET repo as a sibling directory."
  exit 1
fi

echo "==> Configuring Podman to use minikube's daemon..."
eval $(minikube podman-env)

echo "==> Building SPA image..."
podman build -t eregulations/spa:latest "$SPA_CONTEXT"

echo "==> Building WebAPI image..."
podman build -t eregulations/webapi:latest "$WEBAPI_CONTEXT"

echo ""
echo "==> Images built successfully inside minikube:"
podman images | grep eregulations
