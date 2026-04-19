require "digest"

class S3SetSyncService
  SYNC_BUCKET_ENV_KEY = "S3_ENV_SYNC_BUCKET"

  class << self
    def sync_set_to_s3(env_set, source:)
      mappings_for(env_set).find_each do |mapping|
        content = build_env_content(env_set)
        checksum = Digest::SHA256.hexdigest(content)
        next if mapping.last_synced_checksum == checksum && mapping.last_sync_origin == source

        s3_client.put_text(bucket: sync_bucket, key: mapping.outbound_key, body: content)
        mapping.update!(last_synced_checksum: checksum, last_sync_origin: source, last_synced_at: Time.current)
      end
    end

    def process_s3_event!(object_key:, checksum: nil)
      mapping = find_mapping_for_key(object_key)
      return unless mapping

      body = s3_client.get_text(bucket: sync_bucket, key: object_key)
      parsed = EnvFileParser.parse(body)
      computed_checksum = checksum.presence || Digest::SHA256.hexdigest(body)

      return if mapping.last_synced_checksum == computed_checksum && mapping.last_sync_origin == "ui"

      EnvSetSyncService.call(env_set: mapping.env_set, source: "s3", payload: parsed, sync_to_s3: false)
      mapping.update!(last_synced_checksum: computed_checksum, last_sync_origin: "s3", last_synced_at: Time.current)
    end

    def import_object_to_set!(env_set:, object_key:, source:)
      body = s3_client.get_text(bucket: sync_bucket, key: object_key)
      parsed = EnvFileParser.parse(body)
      EnvSetSyncService.call(env_set: env_set, source: source, payload: parsed)
    end

    private

    def mappings_for(env_set)
      env_set.s3_set_mappings.where(sync_enabled: true)
    end

    def find_mapping_for_key(object_key)
      S3SetMapping.where(sync_enabled: true).find do |mapping|
        mapping.matches_key?(object_key)
      end
    end

    def build_env_content(env_set)
      env_set.env_items.order(:key).map do |item|
        next "#{item.key}=" if item.secret? && !item.has_value?

        "#{item.key}=#{item.value}"
      end.join("\n")
    end

    def sync_bucket
      ENV.fetch(SYNC_BUCKET_ENV_KEY)
    end

    def s3_client
      @s3_client ||= Integrations::AwsS3Client.new
    end
  end
end
