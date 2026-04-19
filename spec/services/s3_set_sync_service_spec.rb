require "rails_helper"

RSpec.describe S3SetSyncService do
  let(:app) { App.create!(name: "S3Sync-#{SecureRandom.hex(4)}", github_repository: "org/s3-sync") }
  let(:app_env) { app.app_envs.create!(name: "develop") }
  let(:env_set) { app_env.env_sets.create!(name: "Sync Set", category: "custom") }

  it "imports object payload and fully replaces existing keys" do
    env_set.env_items.create!(key: "OLD", value_type: "string", value: "old")
    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")

    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:get_text).and_return("NEW=value\nANOTHER=next")
    allow(fake_client).to receive(:put_text)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)

    described_class.import_object_to_set!(env_set: env_set, object_key: "path/file.env", source: "manual_import")

    expect(env_set.env_items.exists?(key: "OLD")).to eq(false)
    expect(env_set.env_items.find_by(key: "NEW").value).to eq("value")
  end
end
