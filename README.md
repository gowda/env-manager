# Env Manager

## Runtime

1. Ruby `3.4.8`
2. Rails `8.1.2`
3. PostgreSQL

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
5. `DB_NAME_DEVELOPMENT` (default `env_manager_development`)
6. `DB_NAME_TEST` (default `env_manager_test`)

## Testing

1. `bundle exec rspec`

## CI

1. Test job runs RSpec against PostgreSQL.
2. Lint job runs RuboCop.
3. Security job runs Brakeman and bundler-audit.
