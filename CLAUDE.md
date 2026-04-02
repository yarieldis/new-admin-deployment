# CLAUDE.md - new-admin-deployment

This file provides guidance to Claude Code when working with the **new-admin-deployment** repository.

## Repository Overview

**Purpose**: Docker-based deployment configuration for the eRegulations administration platform. Orchestrates a .NET Web API backend with a Microsoft SQL Server 2022 database using Docker Compose.

**Status**: Early development (initial commit)

**Technology Stack**:
- Docker / Docker Compose
- .NET Web API (containerized, built from Dockerfile)
- Microsoft SQL Server 2022 (Developer edition)

## Project Structure

```
new-admin-deployment/
├── .env                # Environment variables (DB credentials, paths) — DO NOT COMMIT secrets
├── docker-compose.yml  # Service orchestration (webapi + mssql)
├── CLAUDE.md           # AI assistant instructions
├── AGENTS.md           # Agent configuration
└── README.md           # Project readme
```

> **Note**: A `Dockerfile` for the webapi service is referenced in `docker-compose.yml` but not yet present in the repository.

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

### Web API (`webapi`)
- Built from local `Dockerfile`
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
- Both services communicate over a Docker bridge network (`app_network`)

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

### Docker
The deployment is fully containerized via `docker-compose.yml`. The stack consists of:
1. **webapi** — .NET application serving on port 8080
2. **mssql** — SQL Server 2022 with persistent storage and backup mount

### Database Restoration
SQL Server backups can be placed in the `DATABASE_FOLDER` path, which is mounted at `/var/backups` inside the mssql container. Use `sqlcmd` or SSMS to restore from there.

## Important Notes

- The `Dockerfile` for the webapi service needs to be created or sourced from the application repository.
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

### Port Conflicts
- Port 8080 (webapi) or 1433 (mssql) may already be in use. Change mappings in `docker-compose.yml` if needed.
