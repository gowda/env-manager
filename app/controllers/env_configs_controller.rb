class EnvConfigsController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_config, only: %i[show edit update destroy]

  def index
    @env_configs = @app_env.env_configs.order(:kind)
  end

  def show
  end

  def new
    @env_config = @app_env.env_configs.new
  end

  def edit
  end

  def create
    @env_config = @app_env.env_configs.new(env_config_params)

    if @env_config.save
      redirect_to [@app, @app_env, @env_config], notice: "Environment config was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @env_config.update(env_config_params)
      redirect_to [@app, @app_env, @env_config], notice: "Environment config was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @env_config.destroy!
    redirect_to app_app_env_env_configs_path(@app, @app_env), notice: "Environment config was successfully deleted.", status: :see_other
  end

  private

  def set_app
    @app = App.find(params.expect(:app_id))
  end

  def set_app_env
    @app_env = @app.app_envs.find(params.expect(:app_env_id))
  end

  def set_env_config
    @env_config = @app_env.env_configs.find(params.expect(:id))
  end

  def env_config_params
    params.expect(env_config: [:kind])
  end
end
