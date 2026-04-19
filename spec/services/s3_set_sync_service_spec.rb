require "rails_helper"

RSpec.describe S3SetSyncService do
  let(:app) { create(:app, name: "S3Sync-#{SecureRandom.hex(4)}", github_repository: "org/s3-sync") }
  let(:app_env) { create(:app_env, app: app, name: "develop") }
  let(:env_set) { create(:env_set, app_env: app_env, name: "Sync Set") }

  before do
    described_class.reset_client!
  end

  it "imports object payload and fully replaces existing keys" do
    create(:env_item, env_set: env_set, key: "OLD", value_type: "string", value: "old")
    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")

    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:get_text).and_return("NEW=value\nANOTHER=next")
    allow(fake_client).to receive(:put_text)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)

    described_class.call(action: :import_object, env_set: env_set, object_key: "path/file.env", source: "manual_import")

    expect(env_set.env_items.exists?(key: "OLD")).to eq(false)
    expect(env_set.env_items.find_by(key: "NEW").value).to eq("value")
  end

  it "does not re-upload identical content when previous origin was s3" do
    create(:env_item, env_set: env_set, key: "API_URL", value_type: "string", value: "https://example.com")
    mapping = create(:s3_set_mapping, env_set: env_set, key_pattern: "path/file.env", match_kind: "exact", sync_enabled: true)

    content = "API_URL=https://example.com"
    checksum = Digest::SHA256.hexdigest(content)
    mapping.update!(last_synced_checksum: checksum, last_sync_origin: "s3")

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:put_text)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)

    described_class.call(action: :sync_outbound, env_set: env_set, source: "ui")

    expect(fake_client).not_to have_received(:put_text)
  end

  it "does not re-apply duplicate inbound s3 event when checksum matches" do
    mapping = create(:s3_set_mapping, env_set: env_set, key_pattern: "path/file.env", match_kind: "exact", sync_enabled: true)
    content = "API_URL=https://example.com"
    checksum = Digest::SHA256.hexdigest(content)
    mapping.update!(last_synced_checksum: checksum, last_sync_origin: "s3")

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:get_text).and_return(content)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)
    allow(EnvSetSyncService).to receive(:call)

    described_class.call(action: :process_inbound_event, object_key: "path/file.env", checksum: checksum)

    expect(EnvSetSyncService).not_to have_received(:call)
  end

  it "does not echo inbound s3 sync back to s3" do
    create(:env_item, env_set: env_set, key: "API_URL", value_type: "string", value: "https://old.example.com")
    mapping = create(:s3_set_mapping, env_set: env_set, key_pattern: "path/file.env", match_kind: "exact", sync_enabled: true)
    mapping.update!(last_synced_checksum: "previous-checksum", last_sync_origin: "ui")

    inbound_content = "API_URL=https://new.example.com"
    inbound_checksum = Digest::SHA256.hexdigest(inbound_content)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:get_text).with(bucket: "sync-bucket", key: "path/file.env").and_return(inbound_content)
    allow(fake_client).to receive(:put_text)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)

    described_class.call(action: :process_inbound_event, object_key: "path/file.env", checksum: inbound_checksum)

    expect(fake_client).not_to have_received(:put_text)
    expect(env_set.env_items.find_by(key: "API_URL").value).to eq("https://new.example.com")
    expect(mapping.reload.last_synced_checksum).to eq(inbound_checksum)
    expect(mapping.last_sync_origin).to eq("s3")
  end

  it "prefers exact mapping over prefix mapping" do
    exact_set = create(:env_set, app_env: app_env, name: "Exact Set")
    prefix_set = create(:env_set, app_env: app_env, name: "Prefix Set")
    create(:s3_set_mapping, env_set: exact_set, key_pattern: "apps/api.env", match_kind: "exact", sync_enabled: true)
    create(:s3_set_mapping, :prefix, env_set: prefix_set, key_pattern: "apps/", outbound_identifier: "prefix-set", sync_enabled: true)

    content = "API_URL=https://example.com"
    checksum = Digest::SHA256.hexdigest(content)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:get_text).and_return(content)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)
    allow(EnvSetSyncService).to receive(:call)

    described_class.call(action: :process_inbound_event, object_key: "apps/api.env", checksum: checksum)

    expect(EnvSetSyncService).to have_received(:call).with(
      env_set: exact_set,
      source: "s3",
      payload: { "API_URL" => "https://example.com" },
      sync_to_s3: false
    )
  end

  it "prefers longest matching prefix mapping when multiple prefixes match" do
    broad_set = create(:env_set, app_env: app_env, name: "Broad Prefix Set")
    narrow_set = create(:env_set, app_env: app_env, name: "Narrow Prefix Set")
    create(:s3_set_mapping, :prefix, env_set: broad_set, key_pattern: "apps/", outbound_identifier: "broad", sync_enabled: true)
    create(:s3_set_mapping, :prefix, env_set: narrow_set, key_pattern: "apps/orders/", outbound_identifier: "narrow", sync_enabled: true)

    content = "TOKEN=abc"
    checksum = Digest::SHA256.hexdigest(content)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(fake_client).to receive(:get_text).and_return(content)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)
    allow(EnvSetSyncService).to receive(:call)

    described_class.call(action: :process_inbound_event, object_key: "apps/orders/prod.env", checksum: checksum)

    expect(EnvSetSyncService).to have_received(:call).with(
      env_set: narrow_set,
      source: "s3",
      payload: { "TOKEN" => "abc" },
      sync_to_s3: false
    )
  end
end
