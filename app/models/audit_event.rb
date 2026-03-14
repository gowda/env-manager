class AuditEvent < ApplicationRecord
  belongs_to :env_config
  belongs_to :change_set, optional: true

  validates :action, presence: true
  validates :message, presence: true
end
