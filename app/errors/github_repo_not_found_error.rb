# frozen_string_literal: true

class GithubRepoNotFoundError < StandardError
  attr_reader :repo_name

  def initialize(repo_name)
    @repo_name = repo_name
    super("Repository '#{repo_name}' does not exist or you do not have access.")
  end
end
