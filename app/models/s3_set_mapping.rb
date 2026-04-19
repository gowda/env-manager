class S3SetMapping < ApplicationRecord
  MATCH_KINDS = %w[exact prefix].freeze

  belongs_to :env_set

  validates :key_pattern, presence: true
  validates :match_kind, presence: true, inclusion: { in: MATCH_KINDS }

  def matches_key?(key)
    return false if key.blank?

    if match_kind == "exact"
      key_pattern == key
    else
      key.start_with?(key_pattern)
    end
  end

  def outbound_key
    return key_pattern if match_kind == "exact"

    [key_pattern.delete_suffix("/"), "#{env_set.id}.env"].join("/")
  end
end
