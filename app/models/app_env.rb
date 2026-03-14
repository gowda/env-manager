class AppEnv < ApplicationRecord
  NAMES = %w[develop uat demo main master].freeze

  belongs_to :app
  has_many :env_configs, dependent: :destroy

  validates :name, presence: true, inclusion: { in: NAMES }, uniqueness: { scope: :app_id }
end
