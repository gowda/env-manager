class App < ApplicationRecord
  has_many :app_envs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :github_repository, presence: true
end
