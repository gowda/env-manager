class S3EnvSyncPollerJob < ApplicationJob
  queue_as :default

  def perform
    return if queue_url.blank?

    sqs_client.receive_messages(queue_url: queue_url).each do |message|
      S3EventProcessorService.call(message.body)
      sqs_client.delete_message(queue_url: queue_url, receipt_handle: message.receipt_handle)
    rescue StandardError => e
      log_poller_error(message, e)
      next
    end
  end

  private

  def queue_url
    ENV.fetch("S3_ENV_SYNC_SQS_QUEUE_URL", nil)
  end

  def sqs_client
    @sqs_client ||= Integrations::AwsSqsClient.new
  end

  def log_poller_error(message, exception)
    Rails.logger.error(
      {
        event: "s3_env_sync_poller_job_failed",
        message_id: message.respond_to?(:message_id) ? message.message_id : nil,
        exception_class: exception.class.name,
        exception_message: exception.message
      }.compact.to_json
    )
  end
end
