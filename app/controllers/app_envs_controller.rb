class AppEnvsController < ApplicationController
  before_action :set_app
  before_action :set_app_env, only: %i[show edit update destroy]

  def index
    @app_envs = @app.app_envs.order(:name)
  end

  def show
  end

  def new
    @app_env = @app.app_envs.new
  end

  def edit
  end

  def create
    @app_env = @app.app_envs.new(app_env_params)

    if @app_env.save
      redirect_to [@app, @app_env], notice: "App environment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @app_env.update(app_env_params)
      redirect_to [@app, @app_env], notice: "App environment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @app_env.destroy!
    redirect_to app_app_envs_path(@app), notice: "App environment was successfully deleted.", status: :see_other
  end

  private

  def set_app
    @app = App.find(params.expect(:app_id))
  end

  def set_app_env
    @app_env = @app.app_envs.find(params.expect(:id))
  end

  def app_env_params
    params.expect(app_env: [:name])
  end
end
