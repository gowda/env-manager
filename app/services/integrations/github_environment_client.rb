module Integrations
  class GithubEnvironmentClient
    def sync!(repo:, environment:, variables:, secrets:)
      ensure_environment(repo, environment)
      variables.each { |item| upsert_variable(repo, environment, item[:key], item[:value]) }
      secrets.each { |item| upsert_secret(repo, environment, item[:key], item[:value]) }
    end

    private

    def ensure_environment(repo, environment)
      client.environment(repo, environment)
    end

    def upsert_variable(repo, environment, key, value)
      base = "/repos/#{repo}/environments/#{environment}/variables"
      begin
        client.patch("#{base}/#{key}", { name: key, value: value.to_s })
      rescue Octokit::NotFound
        client.post(base, { name: key, value: value.to_s })
      end
    end

    def upsert_secret(repo, environment, key, value)
      public_key = client.get_actions_environment_public_key(repo, environment)
      encrypted = encrypt(public_key.key, value.to_s)

      client.create_or_update_actions_environment_secret(
        repo,
        environment,
        key,
        {
          encrypted_value: encrypted,
          key_id: public_key.key_id
        }
      )
    end

    def encrypt(base64_public_key, value)
      key = Base64.decode64(base64_public_key)
      box = RbNaCl::Boxes::Sealed.from_public_key(key)
      Base64.strict_encode64(box.encrypt(value))
    end

    def client
      @client ||= Octokit::Client.new(access_token: token)
    end

    def token
      ENV.fetch("GITHUB_TOKEN")
    end
  end
end
