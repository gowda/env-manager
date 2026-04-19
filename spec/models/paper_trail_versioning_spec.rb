require "rails_helper"

RSpec.describe "PaperTrail versioning", type: :model do
  it "tracks app, app_env, env_set and env_item changes" do
    app = App.create!(name: "Versioned-#{SecureRandom.hex(4)}", github_repository: "org/versioned")
    app_env = app.app_envs.create!(name: "develop")
    env_set = app_env.env_sets.create!(name: "Versioned Set", category: "custom")
    env_item = env_set.env_items.create!(key: "API_URL", value_type: "string", value: "https://example.com")

    expect(app.versions).not_to be_empty
    expect(app_env.versions).not_to be_empty
    expect(env_set.versions).not_to be_empty
    expect(env_item.versions).not_to be_empty
  end
end
