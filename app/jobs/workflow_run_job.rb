class WorkflowRunJob < ApplicationJob
  class PartialFailure < StandardError; end

  queue_as :default

  def perform(workflow_run_id)
    workflow_run = WorkflowRun.find(workflow_run_id)
    workflow_run.update!(status: "running", error_message: nil)

    execute(workflow_run)
  rescue PartialFailure => e
    workflow_run&.update!(status: "partially_failed", error_message: e.message)
  rescue StandardError => e
    workflow_run&.update!(status: "failed", error_message: e.message)
    raise
  end

  private

  def execute(workflow_run)
    case workflow_run.workflow_definition.kind
    when "s3_then_ecs_force_deploy"
      execute_s3_then_ecs_force_deploy(workflow_run)
    when "s3_then_github_workflow_dispatch"
      execute_s3_then_github_workflow_dispatch(workflow_run)
    when "github_env_update_then_dispatch_many"
      execute_github_env_update_then_dispatch_many(workflow_run)
    else
      run_step(workflow_run, "execute") { }
    end

    workflow_run.update!(status: "succeeded") if workflow_run.status == "running"
  end

  def execute_s3_then_ecs_force_deploy(workflow_run)
    metadata = workflow_run.workflow_definition.metadata || {}

    run_step(workflow_run, "upload_to_s3") do
      s3_client.put_text(
        bucket: required_metadata!(metadata, "s3_bucket"),
        key: metadata["s3_file"].presence || required_metadata!(metadata, "s3_key"),
        body: env_file_content(workflow_run.env_config)
      )
    end

    run_step(workflow_run, "force_ecs_deploy") do
      ecs_client.force_new_deployment(
        cluster: required_metadata!(metadata, "ecs_cluster"),
        service: required_metadata!(metadata, "ecs_service")
      )
    end
  end

  def execute_s3_then_github_workflow_dispatch(workflow_run)
    metadata = workflow_run.workflow_definition.metadata || {}

    run_step(workflow_run, "upload_to_s3") do
      s3_client.put_text(
        bucket: required_metadata!(metadata, "s3_bucket"),
        key: metadata["s3_file"].presence || required_metadata!(metadata, "s3_key"),
        body: env_file_content(workflow_run.env_config)
      )
    end

    run_step(workflow_run, "github_workflow_dispatch") do
      github_actions_client.dispatch_workflow(
        repo: github_repository(workflow_run, metadata),
        workflow_id: required_metadata!(metadata, "workflow_id"),
        ref: metadata["ref"].presence || workflow_run.env_config.app_env.name,
        inputs: metadata["inputs"] || {}
      )
    end
  end

  def execute_github_env_update_then_dispatch_many(workflow_run)
    metadata = workflow_run.workflow_definition.metadata || {}

    run_step(workflow_run, "update_github_environment") do
      github_environment_client.sync!(
        repo: github_repository(workflow_run, metadata),
        environment: metadata["github_environment"].presence || workflow_run.env_config.app_env.name,
        variables: github_variables(workflow_run.env_config),
        secrets: github_secrets(workflow_run.env_config)
      )
    end

    run_step(workflow_run, "dispatch_github_workflows") do
      dispatches = Array(metadata["workflow_dispatches"])
      failures = []

      dispatches.each do |dispatch|
        github_actions_client.dispatch_workflow(
          repo: github_repository(workflow_run, metadata),
          workflow_id: dispatch.fetch("workflow_id"),
          ref: dispatch["ref"].presence || workflow_run.env_config.app_env.name,
          inputs: dispatch["inputs"] || {}
        )
      rescue StandardError => e
        failures << { workflow_id: dispatch["workflow_id"], error: e.message }
      end

      if failures.any?
        raise PartialFailure, "Dispatch failures: #{failures.map { |item| "#{item[:workflow_id]} (#{item[:error]})" }.join(", ")}"
      end
    end
  end

  def run_step(workflow_run, name)
    step = workflow_run.workflow_run_steps.create!(name: name, status: "running")
    yield
    step.update!(status: "succeeded")
  rescue StandardError => e
    step&.update!(status: "failed", error_message: e.message)
    raise
  end

  def env_file_content(env_config)
    env_config.environment_variables.order(:key).map { |variable| "#{variable.key}=#{variable.value}" }.join("\n")
  end

  def github_variables(env_config)
    env_config.environment_variables.where.not(value_type: "secret").map do |variable|
      { key: variable.key, value: variable.value }
    end
  end

  def github_secrets(env_config)
    env_config.environment_variables.where(value_type: "secret").map do |variable|
      { key: variable.key, value: variable.value }
    end
  end

  def github_repository(workflow_run, metadata)
    metadata["github_repository"].presence || workflow_run.env_config.app_env.app.github_repository
  end

  def required_metadata!(metadata, key)
    value = metadata[key]
    raise ArgumentError, "Missing metadata: #{key}" if value.blank?

    value
  end

  def s3_client
    @s3_client ||= Integrations::AwsS3Client.new
  end

  def ecs_client
    @ecs_client ||= Integrations::AwsEcsClient.new
  end

  def github_actions_client
    @github_actions_client ||= Integrations::GithubActionsClient.new
  end

  def github_environment_client
    @github_environment_client ||= Integrations::GithubEnvironmentClient.new
  end
end
