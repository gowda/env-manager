class WorkflowRun < ApplicationRecord
  STATUSES = %w[queued running succeeded failed partially_failed].freeze

  belongs_to :env_config
  belongs_to :workflow_definition
  belongs_to :change_set, optional: true
  has_many :workflow_run_steps, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :trigger_source, presence: true
end
