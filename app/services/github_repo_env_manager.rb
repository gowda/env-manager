# frozen_string_literal: true

# GitHub Environment Ensurer using Octokit.rb
# Checks if a repository environment exists.
# If it does not exist and create_if_missing: true → creates it (minimal config).
# Throws custom errors for missing repo or (optionally) missing environment.

# require "octokit"

class GithubRepoEnvManager
  attr_reader :repo_name, :env_name

  def initialize(repo_name, env_name)
    @repo_name = repo_name
    @repo_short_name = repo_name.split("/").last
    @env_name = env_name
  end

  def call
    assert_repo_exists!
    assert_repo_env_exists!
  rescue GithubRepoEnvNotFoundError
    generate_terraform_config
  end

  private

  def assert_repo_exists!
    client.repository(repo_name)
  rescue Octokit::NotFound, Octokit::Forbidden
    raise GithubRepoNotFoundError, repo_name
  end

  def assert_repo_env_exists!
    begin
      client.environment(repo_name, env_name)
    rescue Octokit::NotFound
      raise GithubRepoEnvNotFoundError.new(repo_name, env_name)
    rescue Octokit::Forbidden
      raise GithubPermissionError, "Insufficient permissions to access environment '#{env_name}'."
    end
  end

  def create_environment!
    begin
      # Minimal creation (no protection rules). You can pass extra options later if needed.
      env = client.create_or_update_environment(repo_name, env_name, {})
      puts "✅ Successfully created environment '#{env_name}' in #{repo_name}"
      env
    rescue Octokit::UnprocessableEntity => e
      raise GithubPermissionError, "Failed to create environment '#{env_name}': #{e.message}"
    rescue => e
      raise GithubError, "Unexpected error creating environment '#{env_name}': #{e.message}"
    end
  end

  def generate_terraform_config
    template_path = Rails.root.join("app/templates/github_repo_env.tf.erb")

    unless File.exist?(template_path)
      raise Error, "Template not found: #{template_path}"
    end

    template = ERB.new(File.read(template_path), trim_mode: "-")

    # Template expects these two instance variables
    # @repo_name = repo_name
    # @env_name  = env_name

    template.result(binding)
  end

  def client
    return @client if defined?(@client) && @client

    @client = Octokit::Client.new(access_token: token)
    @client.auto_paginate = true
    @client
  end

  def token
    @token ||= ENV.fetch("GITHUB_TOKEN", nil)
  end
end
