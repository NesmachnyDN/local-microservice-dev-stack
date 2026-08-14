# Security policy for this portfolio repository

This repository must remain safe for public distribution.

Do not commit:

- `.env` or developer-specific configuration;
- credentials, tokens, certificates or private keys;
- internal hostnames, IP addresses, repository URLs or VPN configuration;
- real organization, project, microservice, database or topic names from non-public systems;
- IDE workspace files containing local paths or environment variables;
- exported logs or data from internal environments.

Use synthetic examples only. Run `./scripts/check-public-safety.sh` before publication-sensitive changes.
