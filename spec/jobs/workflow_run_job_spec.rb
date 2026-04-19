require "rails_helper"

RSpec.describe WorkflowRunJob, type: :job do
  def setup_records(kind:, metadata:)
    app = create(:app, name: "Job-#{SecureRandom.hex(4)}", github_repository: "org/job")
    app_env = create(:app_env, app: app, name: "develop")
    env_config = app_env.env_configs.create!(kind: "runtime_environment")
    workflow_definition = env_config.workflow_definitions.create!(kind: kind, enabled: true, metadata: metadata)
    workflow_run = env_config.workflow_runs.create!(workflow_definition: workflow_definition, status: "queued", trigger_source: "spec")
    [env_config, workflow_run]
  end

  it "executes s3_then_ecs_force_deploy" do
    env_config, workflow_run = setup_records(
      kind: "s3_then_ecs_force_deploy",
      metadata: {
        "s3_bucket" => "bucket",
        "s3_key" => "path/file.env",
        "ecs_cluster" => "cluster-a",
        "ecs_service" => "service-a"
      }
    )

    env_config.environment_variables.create!(key: "A", value_type: "single_line", value: "1")

    s3_client = instance_double(Integrations::AwsS3Client)
    ecs_client = instance_double(Integrations::AwsEcsClient)

    allow(Integrations::AwsS3Client).to receive(:new).and_return(s3_client)
    allow(Integrations::AwsEcsClient).to receive(:new).and_return(ecs_client)

    expect(s3_client).to receive(:put_text).with(bucket: "bucket", key: "path/file.env", body: "A=1")
    expect(ecs_client).to receive(:force_new_deployment).with(cluster: "cluster-a", service: "service-a")

    described_class.perform_now(workflow_run.id)

    expect(workflow_run.reload.status).to eq("succeeded")
    expect(workflow_run.workflow_run_steps.pluck(:name, :status)).to eq([
      ["upload_to_s3", "succeeded"],
      ["force_ecs_deploy", "succeeded"]
    ])
  end

  it "executes s3_then_github_workflow_dispatch" do
    env_config, workflow_run = setup_records(
      kind: "s3_then_github_workflow_dispatch",
      metadata: {
        "s3_bucket" => "bucket",
        "s3_key" => "build/.env",
        "github_repository" => "org/job",
        "workflow_id" => "deploy.yml",
        "ref" => "main",
        "inputs" => { "force" => "true" }
      }
    )

    env_config.environment_variables.create!(key: "A", value_type: "single_line", value: "1")

    s3_client = instance_double(Integrations::AwsS3Client)
    github_actions_client = instance_double(Integrations::GithubActionsClient)

    allow(Integrations::AwsS3Client).to receive(:new).and_return(s3_client)
    allow(Integrations::GithubActionsClient).to receive(:new).and_return(github_actions_client)

    expect(s3_client).to receive(:put_text).with(bucket: "bucket", key: "build/.env", body: "A=1")
    expect(github_actions_client).to receive(:dispatch_workflow).with(
      repo: "org/job",
      workflow_id: "deploy.yml",
      ref: "main",
      inputs: { "force" => "true" }
    )

    described_class.perform_now(workflow_run.id)

    expect(workflow_run.reload.status).to eq("succeeded")
    expect(workflow_run.workflow_run_steps.pluck(:name, :status)).to eq([
      ["upload_to_s3", "succeeded"],
      ["github_workflow_dispatch", "succeeded"]
    ])
  end

  it "marks partially_failed when github_env_update_then_dispatch_many has dispatch failures" do
    env_config, workflow_run = setup_records(
      kind: "github_env_update_then_dispatch_many",
      metadata: {
        "github_repository" => "org/job",
        "github_environment" => "develop",
        "workflow_dispatches" => [
          { "workflow_id" => "ok.yml", "ref" => "develop", "inputs" => {} },
          { "workflow_id" => "bad.yml", "ref" => "develop", "inputs" => {} }
        ]
      }
    )

    env_config.environment_variables.create!(key: "PUBLIC_API", value_type: "single_line", value: "url")
    env_config.environment_variables.create!(key: "SECRET_TOKEN", value_type: "secret", value: "token")

    github_environment_client = instance_double(Integrations::GithubEnvironmentClient)
    github_actions_client = instance_double(Integrations::GithubActionsClient)

    allow(Integrations::GithubEnvironmentClient).to receive(:new).and_return(github_environment_client)
    allow(Integrations::GithubActionsClient).to receive(:new).and_return(github_actions_client)

    expect(github_environment_client).to receive(:sync!).with(
      repo: "org/job",
      environment: "develop",
      variables: [{ key: "PUBLIC_API", value: "url" }],
      secrets: [{ key: "SECRET_TOKEN", value: "token" }]
    )

    expect(github_actions_client).to receive(:dispatch_workflow).with(repo: "org/job", workflow_id: "ok.yml", ref: "develop", inputs: {})
    expect(github_actions_client).to receive(:dispatch_workflow).with(repo: "org/job", workflow_id: "bad.yml", ref: "develop", inputs: {}).and_raise(StandardError, "dispatch error")

    described_class.perform_now(workflow_run.id)

    expect(workflow_run.reload.status).to eq("partially_failed")
    expect(workflow_run.workflow_run_steps.pluck(:name, :status)).to eq([
      ["update_github_environment", "succeeded"],
      ["dispatch_github_workflows", "failed"]
    ])
  end
end
