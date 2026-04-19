module Integrations
  class AwsSqsClient
    def receive_messages(queue_url:, max_number_of_messages: 10, wait_time_seconds: 10)
      client.receive_message(
        queue_url: queue_url,
        max_number_of_messages: max_number_of_messages,
        wait_time_seconds: wait_time_seconds
      ).messages
    end

    def delete_message(queue_url:, receipt_handle:)
      client.delete_message(queue_url: queue_url, receipt_handle: receipt_handle)
    end

    private

    def client
      @client ||= Aws::SQS::Client.new(region: aws_region)
    end

    def aws_region
      ENV.fetch("AWS_REGION", "us-east-1")
    end
  end
end
