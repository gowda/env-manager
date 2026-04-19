# Copilot Repository Instructions

## Secrets and Configuration

- Never implement changes using Rails credentials (`config/credentials*.yml.enc`) or `RAILS_MASTER_KEY`.
- Do not add or reintroduce `config/credentials.yml.enc`.
- All required runtime secrets and configuration must be provided through environment variables.
- For required secrets, prefer explicit `ENV.fetch(...)` access so missing configuration fails fast at boot.
