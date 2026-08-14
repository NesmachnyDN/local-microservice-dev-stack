# Local Microservice Dev Stack

A one-command local infrastructure bootstrap for microservice development.

The project provisions disposable PostgreSQL databases and a single-node Apache Kafka broker with Docker Compose, while application microservices stay outside Docker and run directly from the IDE. This keeps breakpoints, hot reload, runtime variables, profilers and debugger tooling immediately available to the developer.

## Problem

A microservice rarely runs in isolation. Local development often requires databases, message brokers and neighboring infrastructure before the service under development can even start. Recreating those dependencies manually is slow and error-prone, and stale local state can make defects difficult to reproduce.

This toolkit makes the infrastructure boundary explicit:

```text
IDE / debugger
    |
    | localhost:5432 / localhost:9092
    v
+-----------------------------------+
| Docker Compose local infrastructure|
|                                   |
| PostgreSQL 18                     |
|  - catalog_db                     |
|  - orders_db                      |
|  - billing_db                     |
|                                   |
| Apache Kafka 4 (KRaft)            |
+-----------------------------------+
```

`reset` is the primary workflow: it removes old volumes, starts a clean stack, waits for health checks and recreates the configured application databases.

## Quick start on Windows

Requirements:

- Docker Desktop with Docker Compose v2
- Windows PowerShell 5.1+ or PowerShell 7+

Double-click:

```text
start.bat
```

or run:

```powershell
.\scripts\dev-stack.ps1 reset
```

The first run creates a git-ignored `.env` file and generates random local-only database credentials.

## Cross-platform CLI

```bash
./scripts/dev-stack.sh reset   # destroy local state and start clean
./scripts/dev-stack.sh up      # start without deleting volumes
./scripts/dev-stack.sh status  # show container status
./scripts/dev-stack.sh logs    # follow logs
./scripts/dev-stack.sh down    # stop containers, preserve volumes
./scripts/dev-stack.sh clean   # stop and delete local volumes
```

## Configure databases

Edit the generated `.env` file:

```dotenv
DEV_DATABASES=catalog_db:catalog_app,orders_db:orders_app,billing_db:billing_app
```

Each `database:owner` pair creates an isolated database and login role for a synthetic microservice. Database and role identifiers are validated before SQL is executed.

## Why application services are not started here

That is intentional. The target workflow is local development of one or more services in an IDE, where the developer wants direct access to breakpoints, variables, debugger agents and local code changes. Docker owns the disposable infrastructure; the IDE owns the application process.

If containerized application startup is preferred, it can be added as a Compose profile or an additional Compose file without changing the infrastructure bootstrap model. See [Adding application services](docs/adding-a-service.md).

## Validation

GitHub Actions performs a real integration test on every pull request and push to `main`:

1. scans the repository for common publication risks;
2. validates shell syntax;
3. creates a clean Docker Compose environment;
4. waits for PostgreSQL and Kafka health checks;
5. verifies all configured databases;
6. creates and reads a Kafka topic;
7. exercises the PowerShell status command;
8. removes all containers and volumes.

## Repository structure

```text
compose.yaml                 Infrastructure definition
start.bat                    Windows one-click entry point
scripts/dev-stack.ps1        Windows-first orchestration CLI
scripts/dev-stack.sh         Cross-platform orchestration CLI
scripts/init-databases.sh    PostgreSQL bootstrap logic
scripts/smoke-test.sh        End-to-end infrastructure test
scripts/check-public-safety.sh Publication safety guardrail
docs/                        Design and extension notes
```

## Development approach

This repository is an independent portfolio implementation of a general local-development workflow. Architecture, requirements, use cases and acceptance criteria are human-directed; AI-assisted development tools were used for parts of the implementation, testing and documentation.

The repository contains only synthetic service names, identifiers and configuration. See [ORIGIN.md](ORIGIN.md).
