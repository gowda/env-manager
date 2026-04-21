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

## Production

1. Runtime is designed for ECS Fargate with a single RDS PostgreSQL database.
2. Solid Queue, Solid Cache, and Solid Cable tables live in the same production database.
3. Container listens on port `80`.
4. Health endpoint is `/up`.

## Deployment

1. Provision AWS infrastructure from [`infra/terraform`](/Users/gowda/supertiny/env-manager/infra/terraform).
2. Set GitHub environment variables: `AWS_REGION`, `ECR_REPOSITORY`, `ECS_CLUSTER`, `ECS_SERVICE`
3. Set GitHub environment secret: `AWS_DEPLOY_ROLE_ARN`
4. Run the GitHub Actions `Deploy` workflow to build, push, and roll out a new ECS task definition.

Terraform no longer provisions or reads AWS Secrets Manager values for app runtime configuration. ECS task definitions consume S3 environment files from `environment_file_object_arns` in the exact order provided.

## Deployment runbook: S3 env-file hardening

When using S3 environment files for runtime secrets, treat the bucket as a secrets store and enforce all controls below before deployment.

1. Encryption at rest: enable `SSE-KMS` with a customer-managed KMS key (CMK). Do not rely on SSE-S3 defaults.
2. Key policy: allow decrypt only to the ECS task execution role and required admin/break-glass roles.
3. Bucket public exposure: enable all four S3 Public Access Block settings at account and bucket levels.
4. Bucket policy read scope: allow `s3:GetObject` only for the specific env-file object ARNs and only to the ECS task execution role.
5. Bucket policy transport guard: enforce TLS (`aws:SecureTransport = true`) and deny non-TLS requests.
6. Bucket policy write scope: restrict `s3:PutObject`/`s3:DeleteObject` to trusted automation roles (for example CI/deploy role), not broad principals.
7. Object versioning: enable bucket versioning to support rollback and incident recovery.
8. Access logging: enable server access logging or CloudTrail data events for object-level read/write audit trails.
9. Rotation runbook: define and rehearse secret rotation by writing new env-file object versions and forcing ECS deployment.
10. Least-privilege review: regularly validate IAM and bucket policies to ensure no wildcard principals or broad object access.

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
