require "rails_helper"

RSpec.describe S3EventProcessorService do
  describe ".call" do
    it "parses records and invokes inbound sync for ObjectCreated events" do
      payload = {
        "Records" => [
          {
            "eventName" => "ObjectCreated:Put",
            "s3" => {
              "object" => {
                "key" => "apps/prod.env",
                "eTag" => "abc123"
              }
            }
          }
        ]
      }

      allow(S3SetSyncService).to receive(:call)

      described_class.call(payload.to_json)

      expect(S3SetSyncService).to have_received(:call).with(
        action: :process_inbound_event,
        object_key: "apps/prod.env",
        checksum: "abc123"
      )
    end

    it "treats missing Records as empty and does not invoke inbound sync" do
      payload = { "Type" => "Notification" }
      allow(S3SetSyncService).to receive(:call)

      described_class.call(payload.to_json)

      expect(S3SetSyncService).not_to have_received(:call)
    end

    it "ignores non-ObjectCreated events" do
      payload = {
        "Records" => [
          {
            "eventName" => "ObjectRemoved:Delete",
            "s3" => { "object" => { "key" => "apps/prod.env", "eTag" => "zzz" } }
          }
        ]
      }
      allow(S3SetSyncService).to receive(:call)

      described_class.call(payload.to_json)

      expect(S3SetSyncService).not_to have_received(:call)
    end

    it "unescapes URL-encoded object keys before invoking inbound sync" do
      payload = {
        "Records" => [
          {
            "eventName" => "ObjectCreated:Post",
            "s3" => {
              "object" => {
                "key" => "apps%2Fprod%20env.env",
                "eTag" => "etag-1"
              }
            }
          }
        ]
      }
      allow(S3SetSyncService).to receive(:call)

      described_class.call(payload.to_json)

      expect(S3SetSyncService).to have_received(:call).with(
        action: :process_inbound_event,
        object_key: "apps/prod env.env",
        checksum: "etag-1"
      )
    end
  end
end
