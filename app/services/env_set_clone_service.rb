class EnvSetCloneService
  def self.call(...)
    new(...).call
  end

  def initialize(source_set:, destination_app_id:, destination_app_env_id:, destination_new_environment_name:, clone_name:, selected_secret_keys:)
    @source_set = source_set
    @destination_app_id = destination_app_id
    @destination_app_env_id = destination_app_env_id
    @destination_new_environment_name = destination_new_environment_name
    @clone_name = clone_name
    @selected_secret_keys = Array(selected_secret_keys)
  end

  def call
    ActiveRecord::Base.transaction do
      destination_env = resolve_destination_env
      source_version_id = @source_set.versions.last&.id

      cloned_set = destination_env.env_sets.create!(
        name: clone_name,
        category: @source_set.category,
        ui_editable: @source_set.ui_editable,
        cloned_from_version_id: source_version_id
      )

      @source_set.env_items.find_each do |item|
        clone_item(cloned_set, item)
      end

      EnvSetSyncService.call(env_set: cloned_set, source: "clone")
      cloned_set
    end
  end

  private

  def resolve_destination_env
    destination_app = App.find(@destination_app_id)

    if @destination_app_env_id.present?
      return destination_app.app_envs.find(@destination_app_env_id)
    end

    env_name = @destination_new_environment_name.to_s.strip
    raise ArgumentError, "Destination environment is required" if env_name.empty?

    destination_app.app_envs.create!(name: env_name)
  end

  def clone_name
    name = @clone_name.to_s.strip
    return "Copy of #{@source_set.name}" if name.empty?

    name
  end

  def clone_item(cloned_set, source_item)
    if source_item.secret? && !@selected_secret_keys.include?(source_item.key)
      cloned_set.env_items.create!(
        key: source_item.key,
        value_type: source_item.value_type,
        value: nil,
        value_present: false
      )
      return
    end

    cloned_set.env_items.create!(
      key: source_item.key,
      value_type: source_item.value_type,
      value: source_item.value,
      value_present: source_item.secret? ? source_item.value_present : true
    )
  end
end
