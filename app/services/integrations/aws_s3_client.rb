module Integrations
  class AwsS3Client
    def put_text(bucket:, key:, body:)
      client.put_object(bucket: bucket, key: key, body: body)
    end

    def get_text(bucket:, key:)
      client.get_object(bucket: bucket, key: key).body.read
    end

    private

    def client
      @client ||= Aws::S3::Client.new(region: aws_region)
    end

    def aws_region
      ENV.fetch("AWS_REGION", "us-east-1")
    end
  end
end
