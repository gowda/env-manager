FactoryBot.define do
  factory :env_item do
    association :env_set
    sequence(:key) { |n| "KEY_#{n}" }
    value_type { "string" }
    value { "value" }
    value_present { true }

    trait :secret do
      value_type { "secret" }
    end

    trait :unset_secret do
      value_type { "secret" }
      value { nil }
      value_present { false }
    end
  end
end
