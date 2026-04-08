#Requires -Version 5.1
<#
.SYNOPSIS
    Initial minikube setup for eRegulations.
.DESCRIPTION
    Starts minikube with Podman driver, enables ingress addon,
    and deploys shared MSSQL infrastructure.
.EXAMPLE
    .\scripts\setup-minikube.ps1
#>
$ErrorActionPreference = 'Stop'

Write-Host "==> Starting minikube with Podman driver..." -ForegroundColor Cyan
minikube start --driver=podman --memory=4096 --cpus=2
if ($LASTEXITCODE -ne 0) { throw "minikube start failed" }

Write-Host "==> Enabling ingress addon..." -ForegroundColor Cyan
minikube addons enable ingress
if ($LASTEXITCODE -ne 0) { throw "Failed to enable ingress addon" }

Write-Host "==> Deploying infrastructure (MSSQL)..." -ForegroundColor Cyan
minikube kubectl -- apply -f infrastructure/
if ($LASTEXITCODE -ne 0) { throw "Failed to apply infrastructure manifests" }

Write-Host "==> Waiting for MSSQL to be ready..." -ForegroundColor Cyan
minikube kubectl -- -n infrastructure rollout status statefulset/mssql --timeout=120s
if ($LASTEXITCODE -ne 0) { throw "MSSQL rollout timed out" }

$minikubeIp = minikube ip

Write-Host ""
Write-Host "==> Minikube is ready." -ForegroundColor Green
Write-Host "    MSSQL is running in the 'infrastructure' namespace."
Write-Host ""
Write-Host "    Next steps:"
Write-Host "      1. Build images:  .\scripts\build-images.ps1"
Write-Host "      2. Deploy tenant: .\scripts\deploy-tenant.ps1 -TenantName tanzania"
Write-Host ""
Write-Host "    Minikube IP: $minikubeIp"
