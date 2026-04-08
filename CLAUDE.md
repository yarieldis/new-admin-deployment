# CLAUDE.md - new-admin-deployment

This file provides guidance to Claude Code when working with the **new-admin-deployment** repository.

## Repository Overview

**Purpose**: Kubernetes-based multi-tenant deployment configuration for the eRegulations administration platform. Deploys per-tenant Angular SPA + .NET Web API pairs with a shared Microsoft SQL Server 2022 instance using Helm on minikube.

**Status**: Early development

**Technology Stack**:
- Kubernetes (minikube) with Podman driver
- Helm 3 (chart-based tenant deployment)
- Angular 19 SPA (served via nginx)
- .NET 8 Web API (containerized)
- Microsoft SQL Server 2022 (Developer edition, StatefulSet)

## Project Structure

```
new-admin-deployment/
├── .gitignore             # Git ignore rules
├── CLAUDE.md              # AI assistant instructions
├── AGENTS.md              # Agent configuration
├── README.md              # Project readme
├── helm/
│   └── eregulations/      # Helm chart for tenant deployment (spa + webapi)
│       ├── Chart.yaml
│       ├── values.yaml    # Default values
│       └── templates/     # K8s manifest templates
├── infrastructure/        # Shared infrastructure K8s manifests (MSSQL)
│   ├── namespace.yaml
│   ├── mssql-secret.yaml
│   ├── mssql-service.yaml
│   └── mssql-statefulset.yaml
├── tenants/               # Per-tenant Helm value overrides
│   ├── tanzania.yaml
│   └── example-tenant.yaml
└── scripts/               # Helper scripts for minikube workflow
    ├── setup-minikube.ps1
    ├── build-images.ps1
    ├── deploy-tenant.ps1
    └── delete-tenant.ps1
```

### External Source Repositories

Container images are built from sibling repositories via `scripts/build-images.ps1`:

| Service   | Source Repository                                              | Dockerfile |
|-----------|----------------------------------------------------------------|------------|
| `webapi`  | `../eregulations-net8/eregulations-4.0-admin-api/Project`     | .NET 8 multi-stage build |
| `spa`     | `../angular/eregulations-5.0-admin-spa`                       | Angular 19 multi-stage build (nginx) |

Both repositories must be cloned as siblings to this project for image builds to work.

## Quick Start

### Prerequisites
- [minikube](https://minikube.sigs.k8s.io/) installed
- [Podman](https://podman.io/) installed (used as minikube driver)
- [Helm 3](https://helm.sh/) installed
- PowerShell 5.1+ (included with Windows) or [PowerShell 7+](https://github.com/PowerShell/PowerShell)
- Execution policy allowing local scripts: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`
- Sibling source repositories cloned (see External Source Repositories)

### Running the Stack
```powershell
# 1. Start minikube and deploy shared MSSQL
.\scripts\setup-minikube.ps1

# 2. Build container images inside minikube
.\scripts\build-images.ps1

# 3. Deploy a tenant
.\scripts\deploy-tenant.ps1 -TenantName tanzania
```

## Services

### SPA
- Angular 19 application built with multi-stage Dockerfile (node build + nginx)
- Served via nginx on port **4200**
- Health check at `/health` endpoint
- Deployed as a Kubernetes Deployment per tenant

### Web API
- .NET 8 Web API
- Serves on port **8080**
- Connects to 3 MSSQL databases via connection strings injected from a Kubernetes Secret:
  - **DefaultConnection**: Main tenant database (name set per tenant)
  - **GlobalConnection**: Shared global database (`00-dbe-global`)
  - **ConsistencyConnection**: Consistency database (`00-dbe-consistency`)

### MSSQL Server (shared infrastructure)
- Image: `mcr.microsoft.com/mssql/server:2022-latest`
- Deployed as a StatefulSet in the `infrastructure` namespace
- Accessible at `mssql.infrastructure.svc.cluster.local:1433`
- Uses a PersistentVolumeClaim for data persistence
- Health check via `sqlcmd`

### Networking
- Each tenant gets its own Kubernetes namespace
- An Ingress routes `<tenant>.local` to the tenant's SPA and WebAPI services
- MSSQL is accessible across namespaces via its cluster-internal DNS name

## Configuration

### Tenant Values

Each tenant is configured via a YAML file in `tenants/` (see `tenants/example-tenant.yaml` for the template). Key settings:

| Field              | Description                                    |
|--------------------|------------------------------------------------|
| `tenant.name`      | Tenant identifier                              |
| `tenant.hostname`  | Ingress hostname (e.g., `tanzania.local`)      |
| `database.name`    | Tenant-specific database name                  |
| `database.password` | SA password (must match infrastructure secret) |

### MSSQL Secret

Edit `infrastructure/mssql-secret.yaml` and set the `sa-password` value before running `setup-minikube.ps1`. The password must match the `database.password` in your tenant value files.

## Deployment

### Initial Setup
```powershell
.\scripts\setup-minikube.ps1
.\scripts\build-images.ps1
.\scripts\deploy-tenant.ps1 -TenantName tanzania
```

### Manual Helm Commands
```powershell
# Deploy/upgrade a tenant
helm upgrade --install tanzania .\helm\eregulations -n tanzania --create-namespace -f tenants\tanzania.yaml

# List tenant releases
helm list --all-namespaces

# Remove a tenant
.\scripts\delete-tenant.ps1 -TenantName tanzania
```

### Architecture
- **Infrastructure namespace**: Shared MSSQL StatefulSet accessible at `mssql.infrastructure.svc.cluster.local:1433`
- **Tenant namespaces**: Each tenant gets its own namespace with a SPA Deployment, WebAPI Deployment, Services, and Ingress
- **Ingress**: Routes `<tenant>.local` to the correct namespace (requires minikube ingress addon)

### Database Restoration
Copy `.bak` files into the MSSQL pod and use `sqlcmd` to restore:
```powershell
minikube kubectl -- cp backup.bak infrastructure/mssql-0:/var/opt/mssql/backup.bak
minikube kubectl -- -n infrastructure exec mssql-0 -- /opt/mssql-tools18/bin/sqlcmd `
  -S localhost -U sa -P "YourPassword" -C `
  -Q "RESTORE DATABASE [your-db] FROM DISK = '/var/opt/mssql/backup.bak' WITH REPLACE"
```

## Important Notes

- Dockerfiles live in the source repositories, not in this deployment repo.
- Connection strings use `TrustServerCertificate=True` for internal cluster networking.
- `MultipleActiveResultSets=true` is enabled on all connections.
- Images use `IfNotPresent` pull policy so minikube uses locally-built images.

## Git Workflow

## Version Control Guidelines
 
- **NEVER** commit changes without user approval. Ask systematically for approval before committing.
- Commit messages should be clear and follow convention:
  - ai-tooling: AI agents, automation commands, workflows, or other AI-enabled developer tooling
  - feat: New feature
  - fix: Bug fix
  - docs: Documentation
  - style: Formatting
  - refactor: Code restructuring
  - test: Adding tests
  - chore: Maintenance tasks
- **NEVER** mention AI/Claude authorship in commit messages (no "Generated with Claude Code", "AI-assisted", etc.)

## Troubleshooting

### MSSQL Pod Won't Start
- Verify the SA password in `infrastructure/mssql-secret.yaml` meets SQL Server complexity requirements (min 8 chars, mixed case, numbers, symbols).
- Check minikube has enough memory: `minikube start --memory=4096`
- Check pod status: `minikube kubectl -- -n infrastructure describe pod mssql-0`

### Web API Can't Connect to Database
- Ensure the MSSQL pod is ready: `minikube kubectl -- -n infrastructure get pods`
- Verify the password in `tenants/<name>.yaml` matches the infrastructure secret.
- Test DNS resolution from the tenant namespace: `minikube kubectl -- -n <tenant> run -it --rm debug --image=busybox -- nslookup mssql.infrastructure.svc.cluster.local`

### SPA Won't Build
- Ensure the Angular source repository is present at the sibling path.
- Check that `node_modules` is excluded via `.dockerignore` in the source repo.

### Ingress Not Working
- Verify the ingress addon is enabled: `minikube addons list`
- Add the tenant hostname to your hosts file: `<minikube-ip>  <tenant>.local`
- Get the minikube IP with: `minikube ip`
