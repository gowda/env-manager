class EnvironmentVariablesController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_config
  before_action :set_environment_variable, only: %i[show edit update destroy]

  def index
    @environment_variables = @env_config.environment_variables.order(:key)
  end

  def show
  end

  def new
    @environment_variable = @env_config.environment_variables.new
  end

  def edit
  end

  def create
    @environment_variable = @env_config.environment_variables.new(environment_variable_params)

    if @environment_variable.save
      WorkflowTriggerService.call(env_config: @env_config, trigger_source: "single_change")
      redirect_to [@app, @app_env, @env_config, @environment_variable], notice: "Environment variable was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @environment_variable.update(environment_variable_params)
      WorkflowTriggerService.call(env_config: @env_config, trigger_source: "single_change")
      redirect_to [@app, @app_env, @env_config, @environment_variable], notice: "Environment variable was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @environment_variable.destroy!
    WorkflowTriggerService.call(env_config: @env_config, trigger_source: "single_change")
    redirect_to app_app_env_env_config_environment_variables_path(@app, @app_env, @env_config), notice: "Environment variable was successfully deleted.", status: :see_other
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

  def set_environment_variable
    @environment_variable = @env_config.environment_variables.find(params.expect(:id))
  end

  def environment_variable_params
    params.expect(environment_variable: [:key, :value, :value_type])
  end
end
