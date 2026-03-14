class WorkflowTriggerService
  def self.call(...)
    new(...).call
  end

  attr_reader :env_config, :trigger_source, :change_set

  def initialize(env_config:, trigger_source:, change_set: nil)
    @env_config = env_config
    @trigger_source = trigger_source
    @change_set = change_set
  end

  def call
    runs = env_config.workflow_definitions.where(enabled: true).map do |definition|
      run = env_config.workflow_runs.create!(
        workflow_definition: definition,
        change_set: change_set,
        status: "queued",
        trigger_source: trigger_source
      )
      WorkflowRunJob.perform_later(run.id)
      run
    end

    return runs if runs.empty?

    env_config.audit_events.create!(
      change_set: change_set,
      action: "workflows_enqueued",
      message: "Workflow runs enqueued",
      metadata: {
        total: runs.size,
        run_ids: runs.map(&:id)
      }
    )

    runs
  end
end
