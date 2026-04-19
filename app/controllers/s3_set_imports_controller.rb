class S3SetImportsController < ApplicationController
  before_action :set_app
  before_action :set_app_env

  def new
    @apps = App.order(:name)
    @env_sets = @app_env.env_sets.order(:name)
  end

  def create
    target_set = nil
    ActiveRecord::Base.transaction do
      target_set = resolve_target_set
      S3SetSyncService.call(
        action: :import_object,
        env_set: target_set,
        object_key: import_params[:object_key],
        source: "manual_import"
      )
    end

    redirect_to [target_set.app_env.app, target_set.app_env, target_set], notice: "S3 object imported successfully."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @apps = App.order(:name)
    @env_sets = @app_env.env_sets.order(:name)
    @import_error = e.message
    render :new, status: :unprocessable_content
  end

  private

  def set_app
    @app = App.find(params.expect(:app_id))
  end

  def set_app_env
    @app_env = @app.app_envs.find(params.expect(:app_env_id))
  end

  def import_params
    params.expect(s3_import: [:object_key, :destination_app_id, :destination_app_env_id, :destination_new_environment_name, :destination_env_set_id, :destination_new_set_name])
  end

  def resolve_target_set
    destination_app = App.find(import_params[:destination_app_id].presence || @app.id)
    destination_env = if import_params[:destination_app_env_id].present?
      destination_app.app_envs.find(import_params[:destination_app_env_id])
    elsif import_params[:destination_new_environment_name].present?
      destination_app.app_envs.create!(name: import_params[:destination_new_environment_name])
    else
      @app_env
    end

    return destination_env.env_sets.find(import_params[:destination_env_set_id]) if import_params[:destination_env_set_id].present?

    name = import_params[:destination_new_set_name].presence || "Imported Set"
    destination_env.env_sets.create!(name: name, category: "custom")
  end
end
