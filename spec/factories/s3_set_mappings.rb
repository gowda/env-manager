FactoryBot.define do
  factory :s3_set_mapping do
    association :env_set
    sequence(:key_pattern) { |n| "apps/#{n}.env" }
    match_kind { "exact" }
    sync_enabled { true }

    trait :prefix do
      sequence(:key_pattern) { |n| "apps/prefix-#{n}/" }
      match_kind { "prefix" }
      sequence(:outbound_identifier) { |n| "set-#{n}" }
    end
  end
end
