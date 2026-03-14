class WorkflowRunStep < ApplicationRecord
  STATUSES = %w[queued running succeeded failed skipped].freeze

  belongs_to :workflow_run

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
end
