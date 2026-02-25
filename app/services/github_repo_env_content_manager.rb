# frozen_string_literal: true

# GitHub Environment Manager using Octokit.rb
# Manages secrets (encrypted) and variables for a specific repository environment.
#
# Usage (CLI):
#   ruby github_env_manager.rb <owner/repo> <environment> '[secrets_json]' '[variables_json]'
#
# Example:
#   ruby github_env_manager.rb "octokit/octokit.rb" "production" \
#     '[{"key":"API_TOKEN","value":"abc123"}]' \
#     '[{"key":"ENV","value":"prod"}]'
#
# Requirements:
#   gem install octokit rbnacl
#
# Environment:
#   GITHUB_TOKEN (required) - Personal Access Token or GitHub App token with
#   repo scope (for secrets/variables) and admin:repo_hook if needed.

# require 'octokit'
# require 'json'
# require 'base64'
# require 'rbnacl'

class GithubRepoEnvContentManager
  def self.call(...)
    new.call(...)
  end

  attr_reader :repo_name, :env_name
  attr_accessor :skipped_secrets, :skipped_variables

  def initialize(repo_name, env_name)
    @repo_name = repo_name
    @env_name = env_name
    @skipped_secrets = []
    @skipped_variables = []
  end

  # Main entry point
  # secrets/variables: Array of {key: String, value: String} or {"key" => , "value" => }
  def manage(secrets = [], variables = [])
    validate_repository_and_environment!

    # Process secrets
    secrets.each_with_index do |item, idx|
      key, value = [ item[:key], item[:value] ]
      next unless valid_item?(key, value, :secret)

      begin
        set_environment_secret(key, value)
        puts "✅ Secret set: #{key}"
      rescue => e
        skipped_secrets << { key: key || "item_#{idx}", reason: e.message }
      end
    end

    # Process variables
    variables.each_with_index do |item, idx|
      key, value = [ item[:key], item[:value] ]
      next unless valid_item?(key, value, :variable)

      begin
        set_environment_variable(key, value)
        puts "✅ Variable set: #{key}"
      rescue => e
        skipped_variables << { key: key || "item_#{idx}", reason: e.message }
      end
    end

    report_skipped(skipped_secrets, skipped_variables)
  end

  private

  def validate_repository_and_environment!
    # Check repository exists
    begin
      client.repository(repo_name)
    rescue Octokit::NotFound, Octokit::Forbidden
      raise GithubRepoNotFoundError, repo_name
    end

    # Check environment exists (raises NotFound if missing)
    begin
      client.environment(repo_name, env_name)
    rescue Octokit::NotFound
      raise GithubRepoEnvNotFoundError.new(repo_name, env_name)
    rescue Octokit::Forbidden
      raise GithubPermissionError, "Insufficient permissions to access environment '#{env_name}'."
    end
  end

  def valid_item?(key, value, type)
    return false if key.blank?
    return false if value.blank?

    # GitHub naming rules (enforced by API too, but pre-filter)
    # Starts with letter or _, alphanumeric + _
    key.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/) && key.length <= 64
  end

  def set_environment_secret(key, value)
    # Encrypt value
    encrypted_value = encrypt_secret(value.to_s)

    # Upsert secret
    client.create_or_update_actions_environment_secret(
      repo_name,
      env_name,
      key,
      {
        encrypted_value: encrypted_value,
        key_id: encryption_key_id
      }
    )
  end

  def encrypt_secret(secret_value)
    encryption_box.encrypt(secret_value).then { |encrypted_bytes| Base64.strict_encode64(encrypted_bytes) }
  end

  def set_environment_variable(key, value)
    base_path = "/repos/#{repo_name}/environments/#{env_name}/variables"
    update_path = "#{base_path}/#{key}"

    # Try update first (PATCH succeeds if exists)
    begin
      client.patch(update_path, { value: value.to_s, name: key })
    rescue Octokit::NotFound
      client.post(base_path, { name: key, value: value.to_s })
    end
  end

  def report_skipped(skipped_secrets, skipped_variables)
    total_skipped = skipped_secrets.size + skipped_variables.size

    if total_skipped.zero?
      puts "\n🎉 All secrets and variables were successfully managed!"
      return
    end

    puts "\n⚠️  #{total_skipped} item(s) were skipped (invalid or API error):"
    unless skipped_secrets.empty?
      puts "\nSkipped Secrets:"
      skipped_secrets.each { |s| puts "  • #{s[:key]}: #{s[:reason]}" }
    end
    unless skipped_variables.empty?
      puts "\nSkipped Variables:"
      skipped_variables.each { |v| puts "  • #{v[:key]}: #{v[:reason]}" }
    end
  end


  def encryption_box
    return @encryption_box if defined?(@encryption_box) && @encryption_box

    @encryption_box = RbNaCl::Boxes::Sealed.from_public_key(encryption_key)
    @encryption_box
  end

  def encryption_key
    @encryption_key ||= Base64.decode64(encryption_key_base64)
  end

  def encryption_key_base64
    @encryption_key_base64 ||= public_key_response.key
  end

  def encryption_key_id
    return @encryption_key_id if defined?(@encryption_key_id) && @encryption_key_id

    @encryption_key_id = public_key_response.key_id

    @encryption_key_id
  end

  def public_key_response
    @public_key_response ||= client.get_actions_environment_public_key(repo_name, env_name)
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

# CLI entrypoint
# if __FILE__ == $0
#   if ARGV.size < 2
#     puts "Usage: ruby #{$PROGRAM_NAME} <repository> <environment> [secrets_json] [variables_json]"
#     puts "  secrets_json / variables_json: JSON array of objects {key, value}"
#     puts "\nExample:"
#     puts "  ruby #{$PROGRAM_NAME} 'owner/repo' 'staging' '[{\"key\":\"MY_SECRET\",\"value\":\"s3cr3t\"}]' '[{\"key\":\"ENV_MODE\",\"value\":\"dev\"}]'"
#     exit 1
#   end

#   repo = ARGV[0]
#   env = ARGV[1]
#   secrets_json = ARGV[2] || '[]'
#   variables_json = ARGV[3] || '[]'

#   begin
#     secrets = JSON.parse(secrets_json, symbolize_names: true)
#     variables = JSON.parse(variables_json, symbolize_names: true)
#   rescue JSON::ParserError => e
#     puts "❌ Invalid JSON for secrets/variables: #{e.message}"
#     exit 1
#   end

#   manager = GithubEnvironmentManager.new
#   manager.manage(repo, env, secrets, variables)
# rescue GithubEnvironmentManager::RepositoryOrEnvironmentNotFoundError => e
#   puts "❌ #{e.message}"
#   exit 1
# rescue GithubEnvironmentManager::Error => e
#   puts "❌ Error: #{e.message}"
#   exit 1
# rescue => e
#   puts "❌ Unexpected error: #{e.message}"
#   exit 1
# end
