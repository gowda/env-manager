class AppEnv < ApplicationRecord
  NAME_FORMAT = /\A(?=.{1,255}\z)[a-z0-9]+(?:-[a-z0-9]+)*\z/

  belongs_to :app
  has_many :env_configs, dependent: :destroy
  has_many :env_sets, dependent: :destroy

  has_paper_trail

  validates :name, presence: true, format: { with: NAME_FORMAT }, uniqueness: { scope: :app_id }

  after_create :seed_default_env_sets

  private

  def seed_default_env_sets
    EnvSet::PREDEFINED_CATEGORIES.each do |category|
      env_sets.find_or_create_by!(name: category.humanize, category: category)
    end
  end
end
