class EnvItem < ApplicationRecord
  VALUE_TYPES = %w[string multi_line_string secret].freeze
  KEY_FORMAT = /\A[A-Z]{1}[A-Z0-9_]+\z/

  belongs_to :env_set

  encrypts :value

  has_paper_trail

  validates :key, presence: true, format: { with: KEY_FORMAT }, uniqueness: { scope: :env_set_id }
  validates :value_type, presence: true, inclusion: { in: VALUE_TYPES }
  validate :validate_value_for_type

  before_validation :normalize_value_presence

  def secret?
    value_type == "secret"
  end

  def safe_display_value
    return "Secret not set" if secret? && !value_present?
    return "Secret configured" if secret?

    value
  end

  private

  def normalize_value_presence
    self.value_type = "string" if value_type.blank?

    if secret?
      self.value_present = false if value_present.nil?
      self.value = nil unless value_present?
      return
    end

    self.value_present = true
  end

  def validate_value_for_type
    if secret?
      return if !value_present? || value.present?

      errors.add(:value, "must be present when secret is marked as set")
      return
    end

    if value.blank?
      errors.add(:value, "can't be blank")
      return
    end

    if value_type == "string" && value.match?(/[\r\n]/)
      errors.add(:value, "must be single line for string type")
    end
  end
end
