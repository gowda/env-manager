class EnvSetsController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_set, only: %i[show edit update destroy clone create_clone]
  before_action :ensure_ui_editable!, only: %i[edit update destroy]

  def index
    @env_sets = @app_env.env_sets.order(:category, :name)
  end

  def show
  end

  def new
    @env_set = @app_env.env_sets.new(category: "custom")
  end

  def create
    @env_set = @app_env.env_sets.new(env_set_params)

    if @env_set.save
      redirect_to [@app, @app_env, @env_set], notice: "Set was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @env_set.update(env_set_params)
      redirect_to [@app, @app_env, @env_set], notice: "Set was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @env_set.destroy!
    redirect_to app_app_env_env_sets_path(@app, @app_env), notice: "Set was successfully deleted.", status: :see_other
  end

  def clone
    @apps = App.order(:name)
    @secret_keys = @env_set.env_items.where(value_type: "secret").order(:key)
  end

  def create_clone
    result = EnvSetCloneService.call(
      source_set: @env_set,
      destination_app_id: clone_params[:destination_app_id],
      destination_app_env_id: clone_params[:destination_app_env_id],
      destination_new_environment_name: clone_params[:destination_new_environment_name],
      clone_name: clone_params[:clone_name],
      selected_secret_keys: clone_params[:selected_secret_keys]
    )

    redirect_to [result.app_env.app, result.app_env, result], notice: "Set cloned successfully."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @apps = App.order(:name)
    @secret_keys = @env_set.env_items.where(value_type: "secret").order(:key)
    @clone_error = e.message
    render :clone, status: :unprocessable_content
  end

  private

  def set_app
    @app = App.find(params.expect(:app_id))
  end

  def set_app_env
    @app_env = @app.app_envs.find(params.expect(:app_env_id))
  end

  def set_env_set
    @env_set = @app_env.env_sets.find(params.expect(:id))
  end

  def env_set_params
    params.expect(env_set: [:name, :category, :ui_editable])
  end

  def clone_params
    raw = params.expect(clone: [:destination_app_id, :destination_app_env_id, :destination_new_environment_name, :clone_name, { selected_secret_keys: [] }])
    raw[:selected_secret_keys] ||= []
    raw
  end

  def ensure_ui_editable!
    return if @env_set.ui_editable?

    redirect_to [@app, @app_env, @env_set], alert: "This set is managed by Terraform and is read-only in UI."
  end
end
