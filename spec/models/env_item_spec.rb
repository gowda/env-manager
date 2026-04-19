require "rails_helper"

RSpec.describe EnvItem, type: :model do
  let(:app) { App.create!(name: "SpecApp-#{SecureRandom.hex(4)}", github_repository: "org/spec-app") }
  let(:app_env) { app.app_envs.create!(name: "develop") }
  let(:env_set) { app_env.env_sets.create!(name: "Runtime", category: "runtime_environment") }

  it "validates key format" do
    item = env_set.env_items.new(key: "bad-key", value_type: "string", value: "x")

    expect(item).not_to be_valid
    expect(item.errors[:key]).to be_present
  end

  it "requires value for non-secret item" do
    item = env_set.env_items.new(key: "API_URL", value_type: "string", value: nil)

    expect(item).not_to be_valid
    expect(item.errors[:value]).to be_present
  end

  it "allows empty secret when has_value is false" do
    item = env_set.env_items.new(key: "TOKEN", value_type: "secret", value: nil, has_value: false)

    expect(item).to be_valid
  end
end
