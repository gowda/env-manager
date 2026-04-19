class App < ApplicationRecord
  has_many :app_envs, dependent: :destroy
  has_many :env_sets, through: :app_envs

  has_paper_trail

  validates :name, presence: true, uniqueness: true
  validates :github_repository, presence: true
end
