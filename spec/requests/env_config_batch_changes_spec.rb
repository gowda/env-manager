require "rails_helper"

RSpec.describe "EnvConfigBatchChanges", type: :request do
  def setup_env
    app = create(:app, name: "Batch-#{SecureRandom.hex(4)}", github_repository: "org/batch")
    app_env = create(:app_env, app: app, name: "develop")
    env_config = app_env.env_configs.create!(kind: "runtime_environment")
    [app, app_env, env_config]
  end

  describe "POST /apps/:app_id/app_envs/:app_env_id/env_configs/:env_config_id/batch_changes" do
    it "returns preview without applying" do
      app, app_env, env_config = setup_env

      expect do
        post app_app_env_env_config_batch_changes_path(app, app_env, env_config), params: {
          preview: "true",
          batch: {
            input: "API_URL=https://example.com",
            reason: "preview"
          }
        }
      end.not_to change(EnvironmentVariable, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Preview")
    end

    it "requires reason for apply" do
      app, app_env, env_config = setup_env

      expect do
        post app_app_env_env_config_batch_changes_path(app, app_env, env_config), params: {
          batch: {
            input: "API_URL=https://example.com",
            reason: "  "
          }
        }
      end.not_to change(EnvironmentVariable, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Reason is required")
    end

    it "applies create, update, and delete with audit records" do
      app, app_env, env_config = setup_env
      env_config.environment_variables.create!(key: "OLD_KEY", value_type: "single_line", value: "old")
      env_config.environment_variables.create!(key: "REMOVE_ME", value_type: "single_line", value: "bye")

      expect do
        post app_app_env_env_config_batch_changes_path(app, app_env, env_config), params: {
          batch: {
            input: <<~INPUT,
              OLD_KEY=new
              NEW_KEY=value
              delete REMOVE_ME
            INPUT
            reason: "sync release values"
          }
        }
      end.to change(EnvironmentVariable, :count).by(0)

      expect(response).to redirect_to(app_app_env_env_config_path(app, app_env, env_config))

      expect(env_config.environment_variables.find_by(key: "OLD_KEY").value).to eq("new")
      expect(env_config.environment_variables.find_by(key: "NEW_KEY")).to be_present
      expect(env_config.environment_variables.find_by(key: "REMOVE_ME")).to be_nil

      expect(env_config.change_sets.count).to eq(1)
      expect(env_config.change_sets.last.reason).to eq("sync release values")
      expect(env_config.change_sets.last.change_entries.count).to eq(3)
      expect(env_config.audit_events.where(action: "batch_change_applied").count).to eq(1)
    end
  end
end
