class EnvConfig < ApplicationRecord
  KINDS = %w[runtime_environment
    github_repository_environment_variables
    github_repository_environment_secrets
    build_environment].freeze

  belongs_to :app_env

  validates :kind, presence: true, inclusion: { in: KINDS }, uniqueness: { scope: :app_env_id }
end
