require "rails_helper"

RSpec.describe EnvSet, type: :model do
  let(:app_env) { create(:app_env, name: "develop") }

  before do
    S3SetSyncService.reset_client!
  end

  it "deletes mapped s3 objects before destroy" do
    env_set = create(:env_set, app_env: app_env, name: "Mapped Set")
    exact_mapping = create(:s3_set_mapping, env_set: env_set, key_pattern: "apps/api.env", match_kind: "exact", sync_enabled: true)
    prefix_mapping = create(:s3_set_mapping, :prefix, env_set: env_set, key_pattern: "apps/prefix", outbound_identifier: "set-prefix", sync_enabled: true)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)
    allow(fake_client).to receive(:delete_object)

    expect(fake_client).to receive(:delete_object).with(bucket: "sync-bucket", key: exact_mapping.outbound_key)
    expect(fake_client).to receive(:delete_object).with(bucket: "sync-bucket", key: prefix_mapping.outbound_key)

    expect { env_set.destroy! }.to change(described_class, :count).by(-1)
  end

  it "aborts destroy when mapped s3 object cleanup fails" do
    env_set = create(:env_set, app_env: app_env, name: "Failing Set")
    create(:s3_set_mapping, env_set: env_set, key_pattern: "apps/api.env", match_kind: "exact", sync_enabled: true)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_BUCKET").and_return("sync-bucket")
    fake_client = instance_double(Integrations::AwsS3Client)
    allow(Integrations::AwsS3Client).to receive(:new).and_return(fake_client)
    allow(fake_client).to receive(:delete_object).and_raise(StandardError, "s3 unavailable")

    expect { env_set.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    expect(env_set.reload).to be_present
  end
end
