# Publication checklist

Before merging a change into the public repository:

- [ ] All names and data are synthetic or explicitly public.
- [ ] No `.env`, keys, certificates, dumps, logs or IDE workspace files are included.
- [ ] No internal hostname, IP address, repository URL or organization-specific identifier is present.
- [ ] `./scripts/check-public-safety.sh` passes.
- [ ] `docker compose config --quiet` passes.
- [ ] A clean `reset` followed by `./scripts/smoke-test.sh` passes.
- [ ] GitHub Actions is green.
