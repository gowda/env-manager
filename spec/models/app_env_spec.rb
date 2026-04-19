require "rails_helper"

RSpec.describe AppEnv, type: :model do
  let(:app) { App.create!(name: "AppEnvSpec-#{SecureRandom.hex(4)}", github_repository: "org/app-env-spec") }

  it "creates default env sets after creation" do
    app_env = app.app_envs.create!(name: "develop")

    categories = app_env.env_sets.pluck(:category)
    expect(categories).to include(*EnvSet::PREDEFINED_CATEGORIES)
  end

  it "rejects invalid name format" do
    app_env = app.app_envs.new(name: " invalid ")

    expect(app_env).not_to be_valid
    expect(app_env.errors[:name]).to be_present
  end
end
