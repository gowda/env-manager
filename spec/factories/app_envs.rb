FactoryBot.define do
  factory :app_env do
    association :app
    sequence(:name) { |n| "env-#{n}" }
  end
end
