class WorkflowRunJob < ApplicationJob
  queue_as :default

  def perform(workflow_run_id)
    workflow_run = WorkflowRun.find(workflow_run_id)
    workflow_run.update!(status: "running", error_message: nil)

    step_names(workflow_run.workflow_definition.kind).each do |step_name|
      step = workflow_run.workflow_run_steps.create!(name: step_name, status: "running")
      step.update!(status: "succeeded")
    end

    workflow_run.update!(status: "succeeded")
  rescue StandardError => e
    workflow_run&.update!(status: "failed", error_message: e.message)
    raise
  end

  private

  def step_names(kind)
    case kind
    when "s3_then_ecs_force_deploy"
      ["upload_to_s3", "force_ecs_deploy"]
    when "s3_then_github_workflow_dispatch"
      ["upload_to_s3", "github_workflow_dispatch"]
    when "github_env_update_then_dispatch_many"
      ["update_github_environment", "dispatch_github_workflows"]
    else
      ["execute"]
    end
  end
end
