require "rails_helper"

RSpec.describe "EnvItems", type: :request do
  def setup_data(ui_editable: true)
    app = create(:app, name: "EnvItems-#{SecureRandom.hex(4)}")
    app_env = create(:app_env, app: app, name: "develop")
    env_set = create(:env_set, app_env: app_env, name: "SetA", ui_editable: ui_editable)
    [app, app_env, env_set]
  end

  it "does not expose secret values in show page" do
    app, app_env, env_set = setup_data
    item = create(:env_item, :secret, env_set: env_set, key: "TOKEN", value: "abcd", value_present: true)

    get app_app_env_env_set_env_item_path(app, app_env, env_set, item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Secret configured")
    expect(response.body).not_to include("abcd")
  end

  it "blocks UI edits when set is read only" do
    app, app_env, env_set = setup_data(ui_editable: false)

    post app_app_env_env_set_env_items_path(app, app_env, env_set), params: {
      env_item: {
        key: "A",
        value_type: "string",
        value: "b"
      }
    }

    expect(response).to have_http_status(:found)
    expect(env_set.env_items.count).to eq(0)
  end
end
