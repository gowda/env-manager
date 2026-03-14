require "rails_helper"

RSpec.describe "AppEnvs", type: :request do
  describe "POST /apps/:app_id/app_envs" do
    it "creates an app environment" do
      app = App.create!(name: "Catalog", github_repository: "org/catalog")

      expect do
        post app_app_envs_path(app), params: {
          app_env: {
            name: "develop"
          }
        }
      end.to change(AppEnv, :count).by(1)

      expect(response).to redirect_to(app_app_env_path(app, AppEnv.last))
    end
  end
end
