# Agent Conventions

## Service Object Convention

- Service objects must expose a single class entrypoint: `.call(...)`.
- Avoid class-specific action methods such as `.execute`, `.perform`, or custom class APIs.
- Keep behavior-specific branching inside instance `#call` (or delegated private instance methods), so callers always use `<ServiceClass>.call(...)`.

## S3 Cleanup Contract

- `EnvSet` destroy-time S3 cleanup is mapping-scoped and best-effort.
- For prefix mappings, cleanup deletes only the canonical outbound object (`<prefix>/<outbound_identifier>.env`).
- Do not implement or assume recursive prefix deletion unless product requirements explicitly change.

## Secrets Policy

- Do not implement new features or fixes using Rails credentials (`config/credentials*.yml.enc`) or `RAILS_MASTER_KEY`.
- All runtime configuration and secret values must come from environment variables managed outside the app.
- Prefer `ENV.fetch` for required secrets so boot fails fast when required values are missing.

## Deployment Ownership

- Do not add cloud-specific IaC or deployment pipeline automation to this repository.
- Keep this repository deployment-target agnostic.
- Publish platform-specific deployment samples in companion repositories (for example `env-manager-aws`).

@AGENTS.local.md
