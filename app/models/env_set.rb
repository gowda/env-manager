class EnvSet < ApplicationRecord
  CATEGORIES = %w[
    runtime_environment
    github_repository_environment_variables
    github_repository_environment_secrets
    build_environment
    custom
  ].freeze

  PREDEFINED_CATEGORIES = CATEGORIES - ["custom"]

  belongs_to :app_env
  has_many :env_items, dependent: :destroy
  has_many :s3_set_mappings, dependent: :destroy

  has_paper_trail

  validates :name, presence: true, uniqueness: { scope: :app_env_id }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  def read_only?
    !ui_editable?
  end
end
