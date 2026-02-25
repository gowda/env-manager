# frozen_string_literal: true

class GithubRepoEnvNotFoundError < StandardError
  attr_reader :repo_name, :env_name

  def initialize(repo_name, env_name)
    @repo_name = repo_name
    @env_name = env_name
    super("Environment '#{env_name}' does not exist in repository '#{repo_name}'.")
  end
end
