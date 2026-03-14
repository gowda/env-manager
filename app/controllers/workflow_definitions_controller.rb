class WorkflowDefinitionsController < ApplicationController
  before_action :set_app
  before_action :set_app_env
  before_action :set_env_config
  before_action :set_workflow_definition, only: %i[edit update destroy]

  def index
    @workflow_definitions = @env_config.workflow_definitions.order(:kind)
  end

  def new
    @workflow_definition = @env_config.workflow_definitions.new
    @metadata_json = "{}"
  end

  def edit
    @metadata_json = JSON.pretty_generate(@workflow_definition.metadata || {})
  end

  def create
    @workflow_definition = @env_config.workflow_definitions.new(workflow_definition_params)

    if @workflow_definition.save
      redirect_to app_app_env_env_config_workflow_definitions_path(@app, @app_env, @env_config), notice: "Workflow definition was successfully created."
    else
      @metadata_json = params.dig(:workflow_definition, :metadata_json).to_s
      render :new, status: :unprocessable_content
    end
  rescue JSON::ParserError
    @workflow_definition = @env_config.workflow_definitions.new
    @workflow_definition.errors.add(:metadata, "must be valid JSON")
    @metadata_json = params.dig(:workflow_definition, :metadata_json).to_s
    render :new, status: :unprocessable_content
  end

  def update
    if @workflow_definition.update(workflow_definition_params)
      redirect_to app_app_env_env_config_workflow_definitions_path(@app, @app_env, @env_config), notice: "Workflow definition was successfully updated."
    else
      @metadata_json = params.dig(:workflow_definition, :metadata_json).to_s
      render :edit, status: :unprocessable_content
    end
  rescue JSON::ParserError
    @workflow_definition.errors.add(:metadata, "must be valid JSON")
    @metadata_json = params.dig(:workflow_definition, :metadata_json).to_s
    render :edit, status: :unprocessable_content
  end

  def destroy
    @workflow_definition.destroy!
    redirect_to app_app_env_env_config_workflow_definitions_path(@app, @app_env, @env_config), notice: "Workflow definition was successfully deleted.", status: :see_other
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

  def set_workflow_definition
    @workflow_definition = @env_config.workflow_definitions.find(params.expect(:id))
  end

  def workflow_definition_params
    raw = params.expect(workflow_definition: [:kind, :enabled, :metadata_json]).to_h
    metadata_json = raw.delete("metadata_json").to_s
    raw["metadata"] = parse_metadata_json(metadata_json)
    raw
  end

  def parse_metadata_json(metadata_json)
    return {} if metadata_json.strip.empty?

    JSON.parse(metadata_json)
  end
end
