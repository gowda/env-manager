class EnvConfigBatchChangesController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_config

  def new
    @batch_input = ""
    @reason = ""
    @preview_items = []
    @errors = []
  end

  def create
    @batch_input = params.expect(batch: [:input, :reason])[:input].to_s
    @reason = params.expect(batch: [:input, :reason])[:reason].to_s

    parser = EnvConfigBatchParser.new(env_config: @env_config, raw_input: @batch_input)
    operations = parser.parse
    @errors = parser.errors

    applier = EnvConfigBatchApplier.new(env_config: @env_config, operations: operations, reason: @reason)
    @preview_items = applier.preview

    if params[:preview] == "true"
      render :new, status: :ok
      return
    end

    if @reason.strip.empty?
      @errors << "Reason is required"
    end

    if @errors.any?
      render :new, status: :unprocessable_content
      return
    end

    applier.apply!
    redirect_to app_app_env_env_config_path(@app, @app_env, @env_config), notice: "Batch change applied successfully."
  rescue ActiveRecord::RecordInvalid => e
    @errors ||= []
    @errors << e.message
    render :new, status: :unprocessable_content
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
end
