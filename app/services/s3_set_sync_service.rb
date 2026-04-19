require "digest"

class S3SetSyncService
  SYNC_BUCKET_ENV_KEY = "S3_ENV_SYNC_BUCKET"

  def self.call(...)
    new(...).call
  end

  def self.reset_client!
    @s3_client = nil
  end

  class << self
    private

    def s3_client
      @s3_client ||= Integrations::AwsS3Client.new
    end
  end

  def initialize(action:, env_set: nil, source: nil, object_key: nil, checksum: nil)
    @action = action.to_sym
    @env_set = env_set
    @source = source
    @object_key = object_key
    @checksum = checksum
  end

  def call
    case @action
    when :sync_outbound
      sync_set_to_s3!
    when :process_inbound_event
      process_s3_event!
    when :import_object
      import_object_to_set!
    when :delete_set_objects
      delete_set_objects!
    else
      raise ArgumentError, "Unsupported action: #{@action}"
    end
  end

  private

  def sync_set_to_s3!
    mappings_for(@env_set).find_each do |mapping|
      content = build_env_content(@env_set)
      checksum = Digest::SHA256.hexdigest(content)
      # Avoid ping-pong uploads: content identity (checksum) is the no-op gate,
      # independent of whether the latest change origin was UI or S3.
      next if mapping.last_synced_checksum == checksum

      s3_client.put_text(bucket: sync_bucket, key: mapping.outbound_key, body: content)
      mapping.update!(last_synced_checksum: checksum, last_sync_origin: @source, last_synced_at: Time.current)
    end
  end

  def process_s3_event!
    mapping = find_mapping_for_key(@object_key)
    return unless mapping

    body = s3_client.get_text(bucket: sync_bucket, key: @object_key)
    parsed = EnvFileParser.parse(body)
    computed_checksum = @checksum.presence || Digest::SHA256.hexdigest(body)

    # SQS is at-least-once. Suppress duplicate event re-application by
    # content identity (checksum), regardless of prior origin.
    return if mapping.last_synced_checksum == computed_checksum

    EnvSetSyncService.call(env_set: mapping.env_set, source: "s3", payload: parsed, sync_to_s3: false)
    mapping.update!(last_synced_checksum: computed_checksum, last_sync_origin: "s3", last_synced_at: Time.current)
  end

  def import_object_to_set!
    body = s3_client.get_text(bucket: sync_bucket, key: @object_key)
    parsed = EnvFileParser.parse(body)
    EnvSetSyncService.call(env_set: @env_set, source: @source, payload: parsed)
  end

  def delete_set_objects!
    mappings = @env_set.s3_set_mappings
    return if mappings.empty?

    bucket = sync_bucket
    # Destroy-time cleanup is best-effort and mapping-scoped.
    # For prefix mappings, this deletes only the canonical outbound file
    # (<prefix>/<outbound_identifier>.env), not every historical key under that prefix.
    mappings.find_each do |mapping|
      s3_client.delete_object(bucket: bucket, key: mapping.outbound_key)
    end
  end

  def mappings_for(env_set)
    env_set.s3_set_mappings.where(sync_enabled: true)
  end

  def find_mapping_for_key(object_key)
    exact_mapping = S3SetMapping.find_by(
      sync_enabled: true,
      match_kind: "exact",
      key_pattern: object_key
    )
    return exact_mapping if exact_mapping

    first_component = object_key.to_s.split("/", 2).first
    prefix_scope = S3SetMapping.where(sync_enabled: true, match_kind: "prefix")

    if first_component.present?
      escaped_component = ActiveRecord::Base.sanitize_sql_like(first_component)
      prefix_scope = prefix_scope.where("key_pattern LIKE ?", "#{escaped_component}%")
    end

    # Prefer the most specific prefix match to avoid ambiguous routing.
    prefix_scope
      .where("? LIKE (key_pattern || '%')", object_key)
      .order(Arel.sql("LENGTH(key_pattern) DESC"), :id)
      .first
  end

  def build_env_content(env_set)
    env_set.env_items.order(:key).map do |item|
      next "#{item.key}=" if item.secret? && !item.value_present?

      "#{item.key}=#{item.value}"
    end.join("\n")
  end

  def sync_bucket
    ENV.fetch(SYNC_BUCKET_ENV_KEY)
  end

  def s3_client
    self.class.send(:s3_client)
  end
end
