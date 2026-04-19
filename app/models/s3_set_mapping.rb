class S3SetMapping < ApplicationRecord
  MATCH_KINDS = %w[exact prefix].freeze
  IDENTIFIER_FORMAT = /\A[A-Za-z0-9._-]+\z/

  belongs_to :env_set

  validates :key_pattern, presence: true
  validates :match_kind, presence: true, inclusion: { in: MATCH_KINDS }
  validates :outbound_identifier,
    presence: true,
    format: { with: IDENTIFIER_FORMAT },
    if: :prefix?

  def exact?
    match_kind == "exact"
  end

  def prefix?
    match_kind == "prefix"
  end

  def matches_key?(key)
    return false if key.blank?

    if exact?
      key_pattern == key
    else
      key.start_with?(key_pattern)
    end
  end

  def outbound_key
    return key_pattern if exact?

    raise ArgumentError, "outbound_identifier is required for prefix mapping" if outbound_identifier.blank?

    [key_pattern.delete_suffix("/"), "#{outbound_identifier}.env"].join("/")
  end
end
