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

  before_destroy :cleanup_mapped_s3_objects, prepend: true

  def read_only?
    !ui_editable?
  end

  private

  def cleanup_mapped_s3_objects
    return if s3_set_mappings.empty?

    S3SetSyncService.call(action: :delete_set_objects, env_set: self)
  rescue StandardError => e
    Rails.logger.error("Failed to cleanup S3 objects for EnvSet #{id}: #{e.class} #{e.message}")
    errors.add(:base, "Unable to cleanup mapped S3 objects before delete")
    throw :abort
  end
end
