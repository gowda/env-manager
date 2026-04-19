# Agent Conventions

## Service Object Convention

- Service objects must expose a single class entrypoint: `.call(...)`.
- Avoid class-specific action methods such as `.execute`, `.perform`, or custom class APIs.
- Keep behavior-specific branching inside instance `#call` (or delegated private instance methods), so callers always use `<ServiceClass>.call(...)`.

## S3 Cleanup Contract

- `EnvSet` destroy-time S3 cleanup is mapping-scoped and best-effort.
- For prefix mappings, cleanup deletes only the canonical outbound object (`<prefix>/<outbound_identifier>.env`).
- Do not implement or assume recursive prefix deletion unless product requirements explicitly change.

@AGENTS.local.md
