# Env Manager
[![CI](https://github.com/gowda/env-manager/actions/workflows/ci.yml/badge.svg)](https://github.com/gowda/env-manager/actions/workflows/ci.yml)
[![CodeQL](https://github.com/gowda/env-manager/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/gowda/env-manager/actions/workflows/github-code-scanning/codeql)

## Runtime

1. Ruby `3.4.8`
2. Rails `8.1.2`
3. PostgreSQL
4. Hotwire (`turbo-rails`, `stimulus-rails`)

## Local Setup

1. `bundle install`
2. `yarn install`
3. `bundle exec rails db:prepare`
4. `bin/dev`

## Database Configuration

1. `DB_HOST` (default `127.0.0.1`)
2. `DB_PORT` (default `5432`)
3. `DB_USERNAME` (default current shell user)
4. `DB_PASSWORD` (optional)
5. `DB_NAME` (default `env_manager_development` in development, `env_manager_test` in test, `env_manager_production` in production)

## Testing

1. `bundle exec rspec`
2. `bin/rubocop`

## CI

1. Test job runs RSpec against PostgreSQL.
2. Build job verifies the production Docker image can be built.
3. Lint job runs RuboCop.
4. Security job runs Brakeman and bundler-audit.

## Production runtime contract

1. The app is deployment-target agnostic.
2. Solid Queue, Solid Cache, and Solid Cable tables live in the same production database.
3. Container listens on port `80`.
4. Health endpoint is `/up`.

## Deployment examples

Deployment automation and infrastructure samples are intentionally maintained outside this repository.

1. AWS deployment sample repository: [`env-manager-aws`](https://github.com/gowda/env-manager-aws)
2. Users are expected to manage infrastructure and rollout workflows in their own deployment repositories.

## Production environment variables

1. `SECRET_KEY_BASE`
2. `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
3. `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
4. `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
5. `DB_HOST`
6. `DB_PORT`
7. `DB_USERNAME`
8. `DB_PASSWORD`
9. `DB_NAME`
10. `RAILS_LOG_LEVEL`
11. `FORCE_SSL`

The app now fails fast at boot if required secret environment variables are missing.

## S3 mapping cleanup contract

1. Deleting an `EnvSet` triggers best-effort S3 cleanup per configured mapping.
2. Cleanup deletes exactly one outbound key per mapping (`mapping.outbound_key`).
3. For prefix mappings, that means only the canonical file (`<prefix>/<outbound_identifier>.env`) is removed.
4. Historical or ad-hoc objects under the same prefix are not recursively deleted.
