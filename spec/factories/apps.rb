FactoryBot.define do
  factory :app do
    sequence(:name) { |n| "App-#{n}" }
    sequence(:github_repository) { |n| "org/repo-#{n}" }
  end
end
