class ChangeSet < ApplicationRecord
  belongs_to :env_config
  has_many :change_entries, dependent: :destroy
  has_many :audit_events, dependent: :nullify

  validates :reason, presence: true
  validates :status, presence: true
end
