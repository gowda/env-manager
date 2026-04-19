require "rails_helper"
require "ostruct"

RSpec.describe S3EnvSyncPollerJob, type: :job do
  it "short-circuits when queue_url is blank" do
    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_SQS_QUEUE_URL", nil).and_return("")
    allow(Integrations::AwsSqsClient).to receive(:new)

    described_class.perform_now

    expect(Integrations::AwsSqsClient).not_to have_received(:new)
  end

  it "receives messages, processes each, and deletes each on success" do
    queue_url = "https://sqs.example.com/q"
    message_one = OpenStruct.new(body: '{"Records":[{"id":"1"}]}', receipt_handle: "r1")
    message_two = OpenStruct.new(body: '{"Records":[{"id":"2"}]}', receipt_handle: "r2")
    sqs_client = instance_double(Integrations::AwsSqsClient)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_SQS_QUEUE_URL", nil).and_return(queue_url)
    allow(Integrations::AwsSqsClient).to receive(:new).and_return(sqs_client)
    allow(sqs_client).to receive(:receive_messages).with(queue_url: queue_url).and_return([message_one, message_two])
    allow(sqs_client).to receive(:delete_message)
    allow(S3EventProcessorService).to receive(:call)

    described_class.perform_now

    expect(S3EventProcessorService).to have_received(:call).with(message_one.body)
    expect(S3EventProcessorService).to have_received(:call).with(message_two.body)
    expect(sqs_client).to have_received(:delete_message).with(queue_url: queue_url, receipt_handle: "r1")
    expect(sqs_client).to have_received(:delete_message).with(queue_url: queue_url, receipt_handle: "r2")
  end

  it "logs processing errors and continues with next messages" do
    queue_url = "https://sqs.example.com/q"
    message_one = OpenStruct.new(body: '{"Records":[{"id":"1"}]}', receipt_handle: "r1", message_id: "m1")
    message_two = OpenStruct.new(body: '{"Records":[{"id":"2"}]}', receipt_handle: "r2", message_id: "m2")
    sqs_client = instance_double(Integrations::AwsSqsClient)
    logger = instance_double(Logger)

    allow(ENV).to receive(:fetch).with("S3_ENV_SYNC_SQS_QUEUE_URL", nil).and_return(queue_url)
    allow(Integrations::AwsSqsClient).to receive(:new).and_return(sqs_client)
    allow(sqs_client).to receive(:receive_messages).with(queue_url: queue_url).and_return([message_one, message_two])
    allow(Rails).to receive(:logger).and_return(logger)
    allow(logger).to receive(:error)
    allow(S3EventProcessorService).to receive(:call).with(message_one.body).and_raise(StandardError, "boom")
    allow(S3EventProcessorService).to receive(:call).with(message_two.body)

    expect(sqs_client).not_to receive(:delete_message).with(queue_url: queue_url, receipt_handle: "r1")
    expect(sqs_client).to receive(:delete_message).with(queue_url: queue_url, receipt_handle: "r2")
    expect(logger).to receive(:error).with(include("\"event\":\"s3_env_sync_poller_job_failed\""))

    described_class.perform_now
  end
end
