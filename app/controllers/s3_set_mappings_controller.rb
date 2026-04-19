class S3SetMappingsController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_set
  before_action :set_mapping, only: :destroy

  def index
    @mappings = @env_set.s3_set_mappings.order(:created_at)
  end

  def new
    @mapping = @env_set.s3_set_mappings.new(match_kind: "exact")
  end

  def create
    @mapping = @env_set.s3_set_mappings.new(mapping_params)

    if @mapping.save
      redirect_to app_app_env_env_set_path(@app, @app_env, @env_set), notice: "S3 mapping was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @mapping.destroy!
    redirect_to app_app_env_env_set_path(@app, @app_env, @env_set), notice: "S3 mapping was successfully deleted.", status: :see_other
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

  def set_mapping
    @mapping = @env_set.s3_set_mappings.find(params.expect(:id))
  end

  def mapping_params
    params.expect(s3_set_mapping: [:key_pattern, :match_kind, :sync_enabled])
  end
end
