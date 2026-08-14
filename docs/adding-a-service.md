# Adding application services

The default design assumes that application microservices are launched from an IDE. This is useful when debugging is the primary workflow.

If a neighboring service is easier to consume as a container, add it in a separate Compose file rather than mixing application lifecycle concerns into the base infrastructure definition.

Example:

```yaml
services:
  example-service:
    image: example-service:local
    profiles: ["apps"]
    environment:
      DB_URL: jdbc:postgresql://postgres:5432/catalog_db
      KAFKA_BOOTSTRAP_SERVERS: kafka:9092
```

Then launch the optional application profile explicitly:

```bash
docker compose -f compose.yaml -f compose.apps.yaml --profile apps up -d
```

For a real project, keep `compose.apps.yaml` in that project's repository when the service configuration is project-specific. Keep this toolkit focused on reusable local infrastructure.
