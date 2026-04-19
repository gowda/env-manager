# Agent Conventions

## Service Object Convention

- Service objects must expose a single class entrypoint: `.call(...)`.
- Avoid class-specific action methods such as `.execute`, `.perform`, or custom class APIs.
- Keep behavior-specific branching inside instance `#call` (or delegated private instance methods), so callers always use `<ServiceClass>.call(...)`.

@AGENTS.local.md
