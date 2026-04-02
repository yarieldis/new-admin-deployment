# new-admin-deployment

Docker Compose deployment configuration for the eRegulations administration platform. Orchestrates a .NET Web API backend with Microsoft SQL Server 2022.

## Services

| Service   | Image / Build        | Port  | Description                        |
|-----------|----------------------|-------|------------------------------------|
| `webapi`  | Local `Dockerfile`   | 8080  | .NET Web API application           |
| `mssql`   | MSSQL Server 2022    | 1433  | SQL Server (Developer edition)     |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- `.env` file configured (see below)

## Configuration

Create a `.env` file in the project root:

```env
MEDIA_FOLDER=/path/to/media
DATABASE_FOLDER=/path/to/sql-backups
DATABASE_PASSWORD=YourStrongPassword123!
DATABASE_NAME=your-database-name
```

| Variable            | Description                                    |
|---------------------|------------------------------------------------|
| `MEDIA_FOLDER`      | Host path to media files (mounted in webapi)   |
| `DATABASE_FOLDER`   | Host path to SQL Server backup files           |
| `DATABASE_PASSWORD`  | SA password for SQL Server                    |
| `DATABASE_NAME`     | Name of the main tenant database               |

## Quick Start

```bash
# Start the stack
docker compose up -d

# Start with rebuild
docker compose up -d --build

# View logs
docker compose logs -f

# Stop the stack
docker compose down
```

The Web API will be available at `http://localhost:8080`.

## Database

The `mssql` service connects to three databases:

- **Default** — Main tenant database (name from `DATABASE_NAME`)
- **Global** — Shared global database (`00-dbe-global`)
- **Consistency** — Consistency database (`00-dbe-consistency`)

### Restoring Backups

Place `.bak` files in your `DATABASE_FOLDER` path. They are available inside the container at `/var/backups`. Use `sqlcmd` or SSMS to restore:

```bash
docker exec -it mssql-eregulations-8 /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DATABASE_PASSWORD" -C \
  -Q "RESTORE DATABASE [your-db] FROM DISK = '/var/backups/your-backup.bak' WITH REPLACE"
```

## Troubleshooting

- **MSSQL won't start**: Ensure the password meets complexity requirements and Docker has at least 2GB of memory.
- **Web API can't connect**: Check that the `mssql` container is healthy (`docker compose ps`) and `.env` values are correct.
- **Port conflicts**: Change port mappings in `docker-compose.yml` if 8080 or 1433 are already in use.
