require "rails_helper"

RSpec.describe "PaperTrail versioning", type: :model do
  it "tracks app, app_env, env_set and env_item changes" do
    app = create(:app)
    app_env = create(:app_env, app: app, name: "develop")
    env_set = create(:env_set, app_env: app_env, name: "Versioned Set")
    env_item = create(:env_item, env_set: env_set, key: "API_URL", value_type: "string", value: "https://example.com")

    expect(app.versions).not_to be_empty
    expect(app_env.versions).not_to be_empty
    expect(env_set.versions).not_to be_empty
    expect(env_item.versions).not_to be_empty
  end
end
