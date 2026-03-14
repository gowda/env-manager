module Integrations
  class GithubActionsClient
    def dispatch_workflow(repo:, workflow_id:, ref:, inputs: {})
      client.post(
        "/repos/#{repo}/actions/workflows/#{workflow_id}/dispatches",
        { ref: ref, inputs: inputs }
      )
    end

    private

    def client
      @client ||= Octokit::Client.new(access_token: token)
    end

    def token
      ENV.fetch("GITHUB_TOKEN")
    end
  end
end
