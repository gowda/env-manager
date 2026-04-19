class EnvSetSyncService
  def self.call(...)
    new(...).call
  end

  def initialize(env_set:, source:, payload: nil, sync_to_s3: true)
    @env_set = env_set
    @source = source
    @payload = payload
    @sync_to_s3 = sync_to_s3
  end

  def call
    apply_payload! if @payload.present?
    S3SetSyncService.sync_set_to_s3(@env_set, source: @source) if @sync_to_s3
    @env_set
  end

  private

  def apply_payload!
    ActiveRecord::Base.transaction do
      existing = @env_set.env_items.index_by(&:key)
      seen_keys = []

      @payload.each do |key, value|
        seen_keys << key
        item = existing[key]

        if item
          next if item.value == value

          item.update!(value: value, has_value: item.secret? ? value.present? : true)
        else
          @env_set.env_items.create!(key: key, value: value, value_type: "string", has_value: value.present?)
        end
      end

      keys_to_delete = existing.keys - seen_keys
      @env_set.env_items.where(key: keys_to_delete).destroy_all if keys_to_delete.any?
    end
  end
end
