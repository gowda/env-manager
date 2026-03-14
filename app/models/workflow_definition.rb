class WorkflowDefinition < ApplicationRecord
  KINDS = %w[
    s3_then_ecs_force_deploy
    s3_then_github_workflow_dispatch
    github_env_update_then_dispatch_many
  ].freeze

  belongs_to :env_config
  has_many :workflow_runs, dependent: :destroy

  validates :kind, presence: true, inclusion: { in: KINDS }
end
