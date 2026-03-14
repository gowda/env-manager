require "rails_helper"

RSpec.describe "EnvConfigs", type: :request do
  describe "POST /apps/:app_id/app_envs/:app_env_id/env_configs" do
    it "creates an environment config" do
      app = App.create!(name: "Accounts", github_repository: "org/accounts")
      app_env = app.app_envs.create!(name: "uat")

      expect do
        post app_app_env_env_configs_path(app, app_env), params: {
          env_config: {
            kind: "runtime_environment"
          }
        }
      end.to change(EnvConfig, :count).by(1)

      expect(response).to redirect_to(app_app_env_env_config_path(app, app_env, EnvConfig.last))
    end
  end
end
