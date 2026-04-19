require "rails_helper"

RSpec.describe "S3SetImports", type: :request do
  it "rolls back destination env/set creation when import fails" do
    app = create(:app, name: "ImportApp-#{SecureRandom.hex(4)}", github_repository: "org/import-app")
    app_env = create(:app_env, app: app, name: "develop")

    allow(S3SetSyncService).to receive(:call).and_raise(ArgumentError, "Invalid .env content")

    expect do
      post app_app_env_s3_set_import_path(app, app_env), params: {
        s3_import: {
          object_key: "apps/prod.env",
          destination_app_id: app.id,
          destination_new_environment_name: "prod",
          destination_new_set_name: "Imported Prod Set"
        }
      }
    end.not_to change(AppEnv, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(app.app_envs.find_by(name: "prod")).to be_nil
    expect(EnvSet.find_by(name: "Imported Prod Set")).to be_nil
  end
end
