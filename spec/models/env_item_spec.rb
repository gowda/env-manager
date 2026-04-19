require "rails_helper"

RSpec.describe EnvItem, type: :model do
  let(:app_env) { create(:app_env, name: "develop") }
  let(:env_set) { create(:env_set, app_env: app_env, name: "Runtime", category: "runtime_environment") }

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

  it "allows empty secret when value_present is false" do
    item = env_set.env_items.new(key: "TOKEN", value_type: "secret", value: nil, value_present: false)

    expect(item).to be_valid
  end

  it "clears secret value when value_present is false" do
    item = create(:env_item, :secret, env_set: env_set, key: "TOKEN", value: "abc123", value_present: true)

    item.update!(value: "stale", value_present: false)

    expect(item.value_present).to eq(false)
    expect(item.value).to be_nil
  end
end
