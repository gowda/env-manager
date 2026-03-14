class ChangeEntry < ApplicationRecord
  OPERATIONS = %w[create update delete].freeze

  belongs_to :change_set

  validates :key, presence: true
  validates :operation, presence: true, inclusion: { in: OPERATIONS }
end
