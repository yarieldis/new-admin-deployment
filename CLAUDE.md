# CLAUDE.md - new-admin-deployment

This file provides guidance to Claude Code when working with the **new-admin-deployment** repository.

## Repository Overview

**Purpose**: Docker-based deployment configuration for the eRegulations administration platform. Orchestrates an Angular SPA frontend, a .NET Web API backend, and a Microsoft SQL Server 2022 database using Docker Compose.

**Status**: Early development

**Technology Stack**:
- Docker / Docker Compose
- Angular 19 SPA (served via nginx)
- .NET 8 Web API (containerized)
- Microsoft SQL Server 2022 (Developer edition)

## Project Structure

```
new-admin-deployment/
├── .env                   # Environment variables (Docker Compose) — DO NOT COMMIT secrets
├── .gitignore             # Git ignore rules
├── docker-compose.yml     # Docker Compose orchestration (legacy single-tenant)
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
    ├── setup-minikube.sh
    ├── build-images.sh
    ├── deploy-tenant.sh
    └── delete-tenant.sh
```

### External Source Repositories

The `docker-compose.yml` references Dockerfiles from sibling repositories:

| Service   | Source Repository                                              | Dockerfile |
|-----------|----------------------------------------------------------------|------------|
| `webapi`  | `../eregulations-net8/eregulations-4.0-admin-api/Project`     | .NET 8 multi-stage build |
| `spa`     | `../angular/eregulations-5.0-admin-spa`                       | Angular 19 multi-stage build (nginx) |

Both repositories must be cloned as siblings to this project for `docker compose build` to work.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- `.env` file configured (see Configuration section)

### Running the Stack
```bash
# Start all services
docker compose up -d

# Start with rebuild
docker compose up -d --build

# Stop all services
docker compose down

# View logs
docker compose logs -f
```

## Services

### SPA (`spa`)
- Angular 19 application built with multi-stage Dockerfile (node build + nginx)
- Served via nginx on port **4200**
- Health check at `/health` endpoint
- Depends on `webapi` service being started

### Web API (`webapi`)
- .NET 8 Web API built from `../eregulations-net8/eregulations-4.0-admin-api/Project/Dockerfile`
- Exposed on port **8080**
- Mounts a host media folder to `/app/media`
- Connects to 3 MSSQL databases:
  - **DefaultConnection**: Main tenant database (name set via `DATABASE_NAME` env var)
  - **GlobalConnection**: Shared global database (`00-dbe-global`)
  - **ConsistencyConnection**: Consistency database (`00-dbe-consistency`)
- Depends on `mssql` service being healthy before starting

### MSSQL Server (`mssql`)
- Image: `mcr.microsoft.com/mssql/server:2022-latest`
- Container name: `mssql-eregulations-8`
- Exposed on port **1433**
- Uses Docker volume `mssql_data` for data persistence
- Mounts host backup folder to `/var/backups`
- Health check: SQL query via `sqlcmd` every 10s (5 retries)

### Networking
- All services communicate over a Docker bridge network (`app_network`)

## Configuration

### Environment Variables (`.env`)

| Variable            | Description                                    |
|---------------------|------------------------------------------------|
| `MEDIA_FOLDER`      | Host path to media files (mounted in webapi)   |
| `DATABASE_FOLDER`   | Host path to SQL Server backup files            |
| `DATABASE_PASSWORD`  | SA password for SQL Server                     |
| `DATABASE_NAME`     | Name of the main tenant database               |

> **Important**: The `.env` file contains sensitive credentials. It must **never** be committed to version control.

## Deployment

### Docker Compose (Single-Tenant / Legacy)
The `docker-compose.yml` runs a single-tenant stack:
1. **spa** — Angular 19 SPA served via nginx on port 4200
2. **webapi** — .NET 8 Web API serving on port 8080
3. **mssql** — SQL Server 2022 with persistent storage and backup mount

### Kubernetes / Minikube (Multi-Tenant)
The Helm chart in `helm/eregulations/` deploys one spa+webapi pair per tenant. MSSQL runs as shared infrastructure.

#### Initial Setup
```bash
# 1. Start minikube and deploy MSSQL
./scripts/setup-minikube.sh

# 2. Build images inside minikube's Docker daemon
./scripts/build-images.sh

# 3. Deploy a tenant
./scripts/deploy-tenant.sh tanzania
```

#### Manual Helm Commands
```bash
# Deploy/upgrade a tenant
helm upgrade --install tanzania ./helm/eregulations -n tanzania --create-namespace -f tenants/tanzania.yaml

# List tenant releases
helm list --all-namespaces

# Remove a tenant
./scripts/delete-tenant.sh tanzania
```

#### Architecture
- **Infrastructure namespace**: Shared MSSQL StatefulSet accessible at `mssql.infrastructure.svc.cluster.local:1433`
- **Tenant namespaces**: Each tenant gets its own namespace with a spa Deployment, webapi Deployment, Services, and Ingress
- **Ingress**: Routes `<tenant>.local` to the correct namespace (requires minikube ingress addon)

### Database Restoration
SQL Server backups can be placed in the `DATABASE_FOLDER` path, which is mounted at `/var/backups` inside the mssql container (Docker Compose) or copied into the MSSQL pod (Kubernetes). Use `sqlcmd` or SSMS to restore from there.

## Important Notes

- Dockerfiles live in the source repositories, not in this deployment repo.
- Connection strings use `TrustServerCertificate=True` for internal Docker networking.
- `MultipleActiveResultSets=true` is enabled on all connections.
- The mssql container name is hardcoded to `mssql-eregulations-8` — be aware of conflicts if running multiple instances.

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

### MSSQL Container Won't Start
- Verify `DATABASE_PASSWORD` meets SQL Server complexity requirements (min 8 chars, mixed case, numbers, symbols).
- Check Docker has enough memory allocated (SQL Server needs at least 2GB).

### Web API Can't Connect to Database
- Ensure the `mssql` container is healthy: `docker compose ps`
- Verify connection strings match the `DATABASE_PASSWORD` and `DATABASE_NAME` in `.env`
- Check the Docker network: `docker network inspect new-admin-deployment_app_network`

### SPA Won't Build
- Ensure the Angular source repository is present at the path referenced in `docker-compose.yml`.
- Check that `node_modules` is excluded via `.dockerignore` in the source repo.

### Port Conflicts
- Port 4200 (spa), 8080 (webapi), or 1433 (mssql) may already be in use. Change mappings in `docker-compose.yml` if needed.
