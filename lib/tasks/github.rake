# frozen_string_literal: true

namespace :github do
  desc "Generate repository environment terraform config"
  task :generate_repo_env_tf, [ :repo_name, :env_name ] => :environment do |t, args|
    repo_name = args[:repo_name]
    env_name = args[:env_name]
    unless repo_name && env_name
      puts "Usage: rake github:generate_repo_env_tf[owner/repo,environment]"
      exit 1
    end

    manager = GithubRepoEnvManager.new(repo_name, env_name)
    puts manager.call
  end

  desc "Sync repository environment secrets and variables"
  task :sync_repo_env, [ :repo_name, :env_name ] => :environment do |t, args|
    repo_name = args[:repo_name]
    env_name = args[:env_name]

    unless repo_name && env_name
      puts "Usage: rake github:sync_repo_environment[owner/repo,environment]"
      exit 1
    end

    manager = GithubRepoEnvContentManager.new(repo_name, env_name)

    # Load secrets and variables from .env files (if they exist)
    secrets_file = Rails.root.join("tmp/github/#{repo_name}/#{env_name}/secrets.env")
    variables_file = Rails.root.join("tmp/github/#{repo_name}/#{env_name}/variables.env")

    secrets = File.exist?(secrets_file) ? Dotenv.load(secrets_file) : []
    variables = File.exist?(variables_file) ? Dotenv.load(variables_file) : []

    manager.manage(secrets, variables)

    if manager.skipped_secrets.any?
      puts "⚠️ Skipped #{manager.skipped_secrets.size} secrets:"
      manager.skipped_secrets.each { |s| puts "  - #{s[:key]}: #{s[:reason]}" }
    end

    if manager.skipped_variables.any?
      puts "⚠️ Skipped #{manager.skipped_variables.size} variables:"
      manager.skipped_variables.each { |v| puts "  - #{v[:key]}: #{v[:reason]}" }
    end
  end
end
