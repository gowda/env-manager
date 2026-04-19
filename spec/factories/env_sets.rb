FactoryBot.define do
  factory :env_set do
    association :app_env
    sequence(:name) { |n| "Set #{n}" }
    category { "custom" }
    ui_editable { true }
  end
end
