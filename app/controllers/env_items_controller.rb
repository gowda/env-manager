class EnvItemsController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_set
  before_action :ensure_ui_editable!, only: %i[new edit create update destroy]
  before_action :set_env_item, only: %i[show edit update destroy]

  def index
    @env_items = @env_set.env_items.order(:key)
  end

  def show
  end

  def new
    @env_item = @env_set.env_items.new
  end

  def edit
  end

  def create
    @env_item = @env_set.env_items.new(env_item_params)

    if @env_item.save
      EnvSetSyncService.call(env_set: @env_set, source: "ui")
      redirect_to [@app, @app_env, @env_set, @env_item], notice: "Item was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @env_item.update(env_item_params)
      EnvSetSyncService.call(env_set: @env_set, source: "ui")
      redirect_to [@app, @app_env, @env_set, @env_item], notice: "Item was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @env_item.destroy!
    EnvSetSyncService.call(env_set: @env_set, source: "ui")
    redirect_to app_app_env_env_set_env_items_path(@app, @app_env, @env_set), notice: "Item was successfully deleted.", status: :see_other
  end

  private

  def set_app
    @app = App.find(params.expect(:app_id))
  end

  def set_app_env
    @app_env = @app.app_envs.find(params.expect(:app_env_id))
  end

  def set_env_set
    @env_set = @app_env.env_sets.find(params.expect(:env_set_id))
  end

  def set_env_item
    @env_item = @env_set.env_items.find(params.expect(:id))
  end

  def env_item_params
    params.expect(env_item: [:key, :value_type, :value, :has_value])
  end

  def ensure_ui_editable!
    return if @env_set.ui_editable?

    redirect_to [@app, @app_env, @env_set], alert: "This set is managed by Terraform and is read-only in UI."
  end
end
