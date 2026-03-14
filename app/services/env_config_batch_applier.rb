class EnvConfigBatchApplier
  attr_reader :env_config, :operations, :reason

  def initialize(env_config:, operations:, reason:)
    @env_config = env_config
    @operations = operations
    @reason = reason.to_s
  end

  def preview
    operations.filter_map do |operation|
      next if operation[:op] == "invalid"

      current = env_config.environment_variables.find_by(key: operation[:key])
      build_preview_item(operation, current)
    end
  end

  def apply!
    raise ArgumentError, "Reason is required" if reason.strip.empty?

    result_items = []

    ActiveRecord::Base.transaction do
      change_set = env_config.change_sets.create!(reason: reason, status: "applied")

      preview.each do |item|
        applied = apply_item(item)
        next unless applied

        change_set.change_entries.create!(
          key: item[:key],
          operation: item[:operation],
          previous_value_type: item[:previous_value_type],
          new_value_type: item[:new_value_type],
          secret: item[:secret],
          metadata: { line_no: item[:line_no] }
        )

        result_items << item
      end

      env_config.audit_events.create!(
        change_set: change_set,
        action: "batch_change_applied",
        message: "Batch change applied",
        metadata: {
          total: result_items.size,
          created: result_items.count { |item| item[:operation] == "create" },
          updated: result_items.count { |item| item[:operation] == "update" },
          deleted: result_items.count { |item| item[:operation] == "delete" }
        }
      )
    end

    result_items
  end

  private

  def build_preview_item(operation, current)
    if operation[:op] == "delete"
      return {
        line_no: operation[:line_no],
        key: operation[:key],
        operation: "delete",
        previous_value_type: current&.value_type,
        new_value_type: nil,
        secret: current&.secret? || false,
        actionable: current.present?
      }
    end

    if current.nil?
      {
        line_no: operation[:line_no],
        key: operation[:key],
        operation: "create",
        previous_value_type: nil,
        new_value_type: operation[:value_type],
        secret: operation[:value_type] == "secret",
        value: operation[:value],
        actionable: true
      }
    elsif current.value != operation[:value] || current.value_type != operation[:value_type]
      {
        line_no: operation[:line_no],
        key: operation[:key],
        operation: "update",
        previous_value_type: current.value_type,
        new_value_type: operation[:value_type],
        secret: operation[:value_type] == "secret",
        value: operation[:value],
        actionable: true,
        current_id: current.id
      }
    else
      {
        line_no: operation[:line_no],
        key: operation[:key],
        operation: "update",
        previous_value_type: current.value_type,
        new_value_type: operation[:value_type],
        secret: operation[:value_type] == "secret",
        value: operation[:value],
        actionable: false,
        current_id: current.id
      }
    end
  end

  def apply_item(item)
    return false unless item[:actionable]

    if item[:operation] == "delete"
      env_config.environment_variables.find_by(key: item[:key])&.destroy!
      return true
    end

    if item[:operation] == "create"
      env_config.environment_variables.create!(
        key: item[:key],
        value_type: item[:new_value_type],
        value: item[:value]
      )
      return true
    end

    record = env_config.environment_variables.find(item[:current_id])
    record.update!(
      value_type: item[:new_value_type],
      value: item[:value]
    )
    true
  end
end
