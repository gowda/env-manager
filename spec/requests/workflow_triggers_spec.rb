require "rails_helper"

RSpec.describe "WorkflowTriggers", type: :request do
  def setup_env
    app = App.create!(name: "Workflow-#{SecureRandom.hex(4)}", github_repository: "org/workflow")
    app_env = app.app_envs.create!(name: "develop")
    env_config = app_env.env_configs.create!(kind: "runtime_environment")
    env_config.workflow_definitions.create!(kind: "s3_then_ecs_force_deploy", enabled: true)
    [app, app_env, env_config]
  end

  it "creates workflow runs on single variable create" do
    app, app_env, env_config = setup_env

    expect do
      post app_app_env_env_config_environment_variables_path(app, app_env, env_config), params: {
        environment_variable: {
          key: "API_URL",
          value_type: "single_line",
          value: "https://example.com"
        }
      }
    end.to change(WorkflowRun, :count).by(1)

    run = WorkflowRun.last
    expect(run.env_config_id).to eq(env_config.id)
    expect(run.trigger_source).to eq("single_change")
  end

  it "creates workflow runs linked to change_set on batch apply" do
    app, app_env, env_config = setup_env

    expect do
      post app_app_env_env_config_batch_changes_path(app, app_env, env_config), params: {
        batch: {
          input: "KEY=value",
          reason: "release change"
        }
      }
    end.to change(WorkflowRun, :count).by(1)

    run = WorkflowRun.last
    expect(run.trigger_source).to eq("batch_change")
    expect(run.change_set).to be_present
    expect(run.change_set.reason).to eq("release change")
  end
end
