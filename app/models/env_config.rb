class EnvConfig < ApplicationRecord
  KINDS = %w[runtime_environment
    github_repository_environment_variables
    github_repository_environment_secrets
    build_environment].freeze

  belongs_to :app_env
  has_many :environment_variables, dependent: :destroy
  has_many :change_sets, dependent: :destroy
  has_many :audit_events, dependent: :destroy
  has_many :workflow_definitions, dependent: :destroy
  has_many :workflow_runs, dependent: :destroy

  validates :kind, presence: true, inclusion: { in: KINDS }, uniqueness: { scope: :app_env_id }
end
