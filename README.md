# new-admin-deployment

Multi-tenant Kubernetes deployment for the eRegulations administration platform. Uses Helm to deploy per-tenant Angular SPA + .NET Web API pairs with a shared Microsoft SQL Server 2022 instance on minikube.

## Architecture

```
minikube cluster
├── infrastructure namespace
│   └── MSSQL StatefulSet (shared by all tenants)
│
├── tenant-a namespace
│   ├── SPA Deployment + Service
│   ├── WebAPI Deployment + Service
│   └── Ingress (tenant-a.local)
│
├── tenant-b namespace
│   ├── SPA Deployment + Service
│   ├── WebAPI Deployment + Service
│   └── Ingress (tenant-b.local)
│
└── ... (one namespace per tenant)
```

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/)
- [Podman](https://podman.io/)
- [Helm 3](https://helm.sh/)
- Sibling source repositories cloned:
  - `../angular/eregulations-5.0-admin-spa` (Angular 19 SPA)
  - `../eregulations-net8/eregulations-4.0-admin-api/Project` (.NET 8 Web API)

## Quick Start

```bash
# 1. Start minikube and deploy shared MSSQL
./scripts/setup-minikube.sh

# 2. Build container images inside minikube
./scripts/build-images.sh

# 3. Deploy a tenant
./scripts/deploy-tenant.sh tanzania
```

Then add the tenant hostname to your hosts file:

```
<minikube-ip>  tanzania.local
```

Get the IP with `minikube ip`.

## Managing Tenants

```bash
# Deploy or upgrade
./scripts/deploy-tenant.sh <tenant-name>

# Remove
./scripts/delete-tenant.sh <tenant-name>

# List all releases
helm list --all-namespaces
```

### Adding a New Tenant

1. Copy `tenants/example-tenant.yaml` to `tenants/<name>.yaml`
2. Set the tenant name, hostname, database name, and password
3. Run `./scripts/deploy-tenant.sh <name>`

## Database

The WebAPI connects to three databases on the shared MSSQL instance:

- **Default** — Tenant-specific database (configured per tenant)
- **Global** — Shared global database (`00-dbe-global`)
- **Consistency** — Consistency database (`00-dbe-consistency`)

### Restoring Backups

```bash
# Copy backup into the MSSQL pod
minikube kubectl -- cp backup.bak infrastructure/mssql-0:/var/opt/mssql/backup.bak

# Restore
minikube kubectl -- -n infrastructure exec mssql-0 -- /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword" -C \
  -Q "RESTORE DATABASE [your-db] FROM DISK = '/var/opt/mssql/backup.bak' WITH REPLACE"
```

## Troubleshooting

- **MSSQL won't start**: Check password complexity and minikube memory (`--memory=4096`).
- **WebAPI can't connect**: Verify tenant password matches `infrastructure/mssql-secret.yaml`.
- **Ingress not working**: Ensure addon is enabled (`minikube addons list`) and hostname is in your hosts file.
- **Images not found**: Run `./scripts/build-images.sh` to build inside minikube's container runtime.
