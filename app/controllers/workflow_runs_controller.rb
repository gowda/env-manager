class WorkflowRunsController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_config
  before_action :set_workflow_run, only: [:show]

  def index
    @workflow_runs = @env_config.workflow_runs.order(created_at: :desc).limit(100)
  end

  def show
  end

  private

  def set_app
    @app = App.find(params.expect(:app_id))
  end

  def set_app_env
    @app_env = @app.app_envs.find(params.expect(:app_env_id))
  end

  def set_env_config
    @env_config = @app_env.env_configs.find(params.expect(:env_config_id))
  end

  def set_workflow_run
    @workflow_run = @env_config.workflow_runs.find(params.expect(:id))
  end
end
