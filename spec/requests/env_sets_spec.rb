require "rails_helper"

RSpec.describe "EnvSets", type: :request do
  def base_entities
    app = App.create!(name: "EnvSets-#{SecureRandom.hex(4)}", github_repository: "org/env-sets")
    app_env = app.app_envs.create!(name: "develop")
    [app, app_env]
  end

  it "creates a set" do
    app, app_env = base_entities

    expect do
      post app_app_env_env_sets_path(app, app_env), params: {
        env_set: {
          name: "Custom Set",
          category: "custom",
          ui_editable: true
        }
      }
    end.to change(EnvSet, :count).by(1)

    expect(response).to redirect_to(app_app_env_env_set_path(app, app_env, EnvSet.last))
  end

  it "clones set and keeps source version mapping" do
    app, app_env = base_entities
    source_set = app_env.env_sets.create!(name: "Source Set", category: "custom")
    source_set.env_items.create!(key: "API_URL", value_type: "string", value: "https://example.com")
    source_set.env_items.create!(key: "TOKEN", value_type: "secret", value: "abc", has_value: true)

    destination_app = App.create!(name: "Destination-#{SecureRandom.hex(4)}", github_repository: "org/destination")
    destination_env = destination_app.app_envs.create!(name: "main")

    expect do
      post clone_app_app_env_env_set_path(app, app_env, source_set), params: {
        clone: {
          destination_app_id: destination_app.id,
          destination_app_env_id: destination_env.id,
          clone_name: "Copy Set",
          selected_secret_keys: []
        }
      }
    end.to change(EnvSet, :count).by(1)

    cloned = EnvSet.last
    expect(cloned.cloned_from_version_id).to eq(source_set.versions.last.id)
    expect(cloned.env_items.find_by(key: "TOKEN").has_value).to eq(false)
  end
end
