# IDE integration

After the stack is ready, configure application run/debug profiles to connect to localhost.

Typical synthetic values:

```text
PostgreSQL host: localhost
PostgreSQL port: 5432
Kafka bootstrap servers: localhost:9092
```

Database names and owners are defined by `DEV_DATABASES` in `.env`. Credentials are generated locally and should be loaded from `.env` or copied into an IDE-local run configuration that is not committed.

The repository intentionally does not provide IntelliJ IDEA, VS Code or other workspace files because those files often accumulate developer-specific paths, credentials or environment metadata.
