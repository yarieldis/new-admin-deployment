#Requires -Version 5.1
<#
.SYNOPSIS
    Build container images inside minikube's Podman daemon.
.DESCRIPTION
    Configures Podman to target minikube's container runtime, then builds
    the SPA and WebAPI images from sibling source repositories.
.EXAMPLE
    .\scripts\build-images.ps1
#>
$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$SpaContext = Join-Path $ProjectRoot "..\angular\eregulations-5.0-admin-spa"
$WebApiContext = Join-Path $ProjectRoot "..\eregulations-net8\eregulations-4.0-admin-api\Project"

# Verify source repos exist
if (-not (Test-Path $SpaContext -PathType Container)) {
    Write-Host "ERROR: SPA source not found at $SpaContext" -ForegroundColor Red
    Write-Host "       Clone the Angular repo as a sibling directory."
    exit 1
}

if (-not (Test-Path $WebApiContext -PathType Container)) {
    Write-Host "ERROR: WebAPI source not found at $WebApiContext" -ForegroundColor Red
    Write-Host "       Clone the .NET repo as a sibling directory."
    exit 1
}

Write-Host "==> Configuring Podman to use minikube's daemon..." -ForegroundColor Cyan
minikube podman-env --shell powershell | Invoke-Expression

Write-Host "==> Building SPA image..." -ForegroundColor Cyan
podman build -t eregulations/spa:latest "$SpaContext"
if ($LASTEXITCODE -ne 0) { throw "SPA image build failed" }

Write-Host "==> Building WebAPI image..." -ForegroundColor Cyan
podman build -t eregulations/webapi:latest "$WebApiContext"
if ($LASTEXITCODE -ne 0) { throw "WebAPI image build failed" }

Write-Host ""
Write-Host "==> Images built successfully inside minikube:" -ForegroundColor Green
podman images | Select-String "eregulations"
