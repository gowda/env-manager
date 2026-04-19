require "cgi"
require "json"

class S3EventProcessorService
  def self.call(message_body)
    payload = JSON.parse(message_body)
    records = payload.fetch("Records", [])

    records.each do |record|
      next unless record.fetch("eventName", "").start_with?("ObjectCreated")

      object_key = CGI.unescape(record.dig("s3", "object", "key").to_s)
      etag = record.dig("s3", "object", "eTag")
      next if object_key.blank?

      S3SetSyncService.process_s3_event!(object_key: object_key, checksum: etag)
    end
  end
end
