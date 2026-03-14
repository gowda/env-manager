module Integrations
  class AwsEcsClient
    def force_new_deployment(cluster:, service:)
      client.update_service(
        cluster: cluster,
        service: service,
        force_new_deployment: true
      )
    end

    private

    def client
      @client ||= Aws::ECS::Client.new(region: aws_region)
    end

    def aws_region
      ENV.fetch("AWS_REGION", "us-east-1")
    end
  end
end
