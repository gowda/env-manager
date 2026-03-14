require "rails_helper"

RSpec.describe "EnvironmentVariables", type: :request do
  def create_base(kind: "runtime_environment")
    app = App.create!(name: "Orders-#{SecureRandom.hex(4)}", github_repository: "org/orders")
    app_env = app.app_envs.create!(name: "develop")
    env_config = app_env.env_configs.create!(kind: kind)

    [app, app_env, env_config]
  end

  describe "POST /apps/:app_id/app_envs/:app_env_id/env_configs/:env_config_id/environment_variables" do
    it "creates variable with default single_line when value_type is missing" do
      app, app_env, env_config = create_base

      expect do
        post app_app_env_env_config_environment_variables_path(app, app_env, env_config), params: {
          environment_variable: {
            key: "API_URL",
            value: "https://example.com"
          }
        }
      end.to change(EnvironmentVariable, :count).by(1)

      expect(EnvironmentVariable.last.value_type).to eq("single_line")
      expect(response).to redirect_to(app_app_env_env_config_environment_variable_path(app, app_env, env_config, EnvironmentVariable.last))
    end

    it "rejects blank value" do
      app, app_env, env_config = create_base

      expect do
        post app_app_env_env_config_environment_variables_path(app, app_env, env_config), params: {
          environment_variable: {
            key: "EMPTY",
            value_type: "single_line",
            value: "   "
          }
        }
      end.not_to change(EnvironmentVariable, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects newline for single_line" do
      app, app_env, env_config = create_base

      expect do
        post app_app_env_env_config_environment_variables_path(app, app_env, env_config), params: {
          environment_variable: {
            key: "BAD",
            value_type: "single_line",
            value: "line1\nline2"
          }
        }
      end.not_to change(EnvironmentVariable, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "allows newline for multi_line" do
      app, app_env, env_config = create_base

      expect do
        post app_app_env_env_config_environment_variables_path(app, app_env, env_config), params: {
          environment_variable: {
            key: "GOOD",
            value_type: "multi_line",
            value: "line1\nline2"
          }
        }
      end.to change(EnvironmentVariable, :count).by(1)

      expect(EnvironmentVariable.last.value_type).to eq("multi_line")
    end

    it "allows only secret value_type for github_repository_environment_secrets" do
      app, app_env, env_config = create_base(kind: "github_repository_environment_secrets")

      expect do
        post app_app_env_env_config_environment_variables_path(app, app_env, env_config), params: {
          environment_variable: {
            key: "TOKEN",
            value_type: "single_line",
            value: "abcd"
          }
        }
      end.not_to change(EnvironmentVariable, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /apps/:app_id/app_envs/:app_env_id/env_configs/:env_config_id/environment_variables/:id" do
    it "masks secret value" do
      app, app_env, env_config = create_base(kind: "github_repository_environment_secrets")
      environment_variable = env_config.environment_variables.create!(key: "TOKEN", value_type: "secret", value: "abcd")

      get app_app_env_env_config_environment_variable_path(app, app_env, env_config, environment_variable)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("••••••••")
      expect(response.body).not_to include("abcd")
    end
  end
end
