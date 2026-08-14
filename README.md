# Local Microservice Dev Stack

A one-command local infrastructure bootstrap for microservice development.

The project provisions disposable infrastructure with Docker Compose while application microservices stay outside Docker and run directly from the IDE. This keeps breakpoints, hot reload, runtime variables, profilers and debugger tooling immediately available to the developer.

## Problem

A microservice rarely runs in isolation. Local development often requires databases and message brokers before the service under development can even start. Recreating those dependencies manually is slow and error-prone, and stale local state can make defects difficult to reproduce.

This toolkit makes the infrastructure boundary explicit:

```text
IDE / debugger
    |
    | localhost
    v
+-----------------------------------+
| Docker Compose local infrastructure|
|                                   |
| PostgreSQL 18                     |
| Apache Kafka 4 (KRaft)            |
| Apache Artemis (optional profile)  |
+-----------------------------------+
```

`reset` is the primary workflow: it removes old volumes, starts a clean selected capability set, waits for Compose readiness and recreates the configured application databases.

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
.\scripts\dev-stack.ps1 reset core
```

The first run creates a git-ignored `.env` file and generates random local-only credentials.

## Capability profiles

The original development workflow used selective infrastructure startup to avoid running services that were not needed for the microservice being debugged. The public edition preserves that idea with safe synthetic configuration.

| Profile | Components | Typical use |
|---|---|---|
| `core` | PostgreSQL + Kafka | Default microservice development |
| `database` | PostgreSQL | Persistence-only work |
| `messaging` | Kafka | Event-driven integration work |
| `broker` | Apache Artemis | JMS/AMQP broker integration |
| `all` | PostgreSQL + Kafka + Artemis | Full local infrastructure |

Examples:

```powershell
.\scripts\dev-stack.ps1 reset database
.\scripts\dev-stack.ps1 reset broker
.\scripts\dev-stack.ps1 reset all
```

```bash
./scripts/dev-stack.sh reset core
./scripts/dev-stack.sh reset messaging
./scripts/dev-stack.sh reset all
```

Docker Compose also reads `COMPOSE_PROFILES=core` from the generated `.env`, so raw `docker compose up` keeps the safe default capability set.

## Cross-platform CLI

```bash
./scripts/dev-stack.sh reset core   # destroy local state and start clean
./scripts/dev-stack.sh up core      # start without deleting volumes
./scripts/dev-stack.sh status core  # show selected container status
./scripts/dev-stack.sh logs core    # follow selected logs
./scripts/dev-stack.sh down         # stop containers, preserve volumes
./scripts/dev-stack.sh clean        # stop and delete local volumes
```

## Configure databases

Edit the generated `.env` file:

```dotenv
DEV_DATABASES=catalog_db:catalog_app,orders_db:orders_app,billing_db:billing_app
```

Each `database:owner` pair creates an isolated database and login role for a synthetic microservice. Database and role identifiers are validated before SQL is executed.

The public edition intentionally creates **clean databases only**. It does not import snapshots from remote development environments.

## Why application services are not started here

That is intentional. The target workflow is local development of one or more services in an IDE, where the developer wants direct access to breakpoints, variables, debugger agents and local code changes. Docker owns the disposable infrastructure; the IDE owns the application process.

If containerized application startup is preferred, it can be added as an additional profile or Compose file without changing the infrastructure bootstrap model. See [Adding application services](docs/adding-a-service.md).

## Validation

GitHub Actions performs real infrastructure checks on every pull request and push to `main`:

1. scans the repository for common publication risks;
2. validates shell syntax;
3. validates the complete Compose model with every profile enabled;
4. starts a clean PostgreSQL + Kafka core stack;
5. verifies all configured databases;
6. creates and reads a Kafka topic;
7. exercises the PowerShell CLI;
8. separately starts and verifies the optional Apache Artemis profile;
9. removes all containers and volumes.

## Repository structure

```text
compose.yaml                   Infrastructure definition and profiles
start.bat                      Windows one-click entry point
scripts/dev-stack.ps1          Windows-first orchestration CLI
scripts/dev-stack.sh           Cross-platform orchestration CLI
scripts/init-databases.sh      PostgreSQL bootstrap logic
scripts/smoke-test.sh          Core infrastructure smoke test
scripts/check-public-safety.sh Publication safety guardrail
docs/                          Design and extension notes
```

## Development approach

This repository is an independent portfolio implementation of a general local-development workflow explored in an earlier discontinued internal development-tooling prototype. Architecture, workflow constraints and acceptance criteria are human-directed; AI-assisted development tools were used for parts of the public reimplementation, testing and documentation.

The repository contains only synthetic service names, identifiers and configuration. It intentionally excludes remote database snapshots, internal hostnames, credentials, organization-specific queue names, proprietary broker configuration and historical source-control data. See [ORIGIN.md](ORIGIN.md).
