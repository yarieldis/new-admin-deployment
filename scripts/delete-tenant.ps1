#Requires -Version 5.1
<#
.SYNOPSIS
    Delete a tenant and its namespace.
.PARAMETER TenantName
    Name of the tenant to remove.
.EXAMPLE
    .\scripts\delete-tenant.ps1 -TenantName tanzania
#>
param(
    [Parameter(Mandatory, HelpMessage = "Tenant name to delete")]
    [string]$TenantName
)

$ErrorActionPreference = 'Stop'

Write-Host "==> Uninstalling Helm release: $TenantName" -ForegroundColor Cyan
helm uninstall $TenantName --namespace $TenantName
if ($LASTEXITCODE -ne 0) { throw "Helm uninstall failed for '$TenantName'" }

Write-Host "==> Deleting namespace: $TenantName" -ForegroundColor Cyan
minikube kubectl -- delete namespace $TenantName
if ($LASTEXITCODE -ne 0) { throw "Failed to delete namespace '$TenantName'" }

Write-Host "==> Tenant '$TenantName' removed." -ForegroundColor Green
