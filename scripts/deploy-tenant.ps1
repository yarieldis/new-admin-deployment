#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy or upgrade a tenant.
.DESCRIPTION
    Deploys the eRegulations Helm chart for a tenant using
    the matching values file from tenants/.
.PARAMETER TenantName
    Name of the tenant to deploy (e.g., tanzania).
    Must have a corresponding tenants/<name>.yaml file.
.EXAMPLE
    .\scripts\deploy-tenant.ps1 -TenantName tanzania
#>
param(
    [Parameter(Mandatory, HelpMessage = "Tenant name (e.g., tanzania)")]
    [string]$TenantName
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$ValuesFile = Join-Path $ProjectRoot "tenants\$TenantName.yaml"

if (-not (Test-Path $ValuesFile -PathType Leaf)) {
    Write-Host "ERROR: Tenant values file not found: $ValuesFile" -ForegroundColor Red
    Write-Host "       Create it first (see tenants\example-tenant.yaml)."
    exit 1
}

Write-Host "==> Deploying tenant: $TenantName" -ForegroundColor Cyan
helm upgrade --install $TenantName "$ProjectRoot\helm\eregulations" `
    --namespace $TenantName `
    --create-namespace `
    -f $ValuesFile
if ($LASTEXITCODE -ne 0) { throw "Helm deploy failed for tenant '$TenantName'" }

Write-Host ""
Write-Host "==> Waiting for rollout..." -ForegroundColor Cyan
minikube kubectl -- -n $TenantName rollout status deployment/${TenantName}-webapi --timeout=90s
if ($LASTEXITCODE -ne 0) { throw "WebAPI rollout timed out" }

minikube kubectl -- -n $TenantName rollout status deployment/${TenantName}-spa --timeout=90s
if ($LASTEXITCODE -ne 0) { throw "SPA rollout timed out" }

$minikubeIp = minikube ip

Write-Host ""
Write-Host "==> Tenant '$TenantName' is deployed." -ForegroundColor Green
Write-Host "    Add to hosts file: $minikubeIp  ${TenantName}.local"
