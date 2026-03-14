class EnvironmentVariable < ApplicationRecord
  VALUE_TYPES = %w[single_line multi_line secret].freeze

  belongs_to :env_config

  encrypts :value

  validates :key, presence: true, uniqueness: { scope: :env_config_id }
  validates :value_type, presence: true, inclusion: { in: VALUE_TYPES }
  validates :value, presence: true
  validate :value_not_blank
  validate :single_line_has_no_newline
  validate :secret_only_for_secret_config

  before_validation :set_default_value_type

  def secret?
    value_type == "secret"
  end

  private

  def set_default_value_type
    self.value_type = "single_line" if value_type.blank?
  end

  def value_not_blank
    return if value.nil?
    return unless value.strip.empty?

    errors.add(:value, "can't be blank")
  end

  def single_line_has_no_newline
    return unless value_type == "single_line"
    return if value.nil?
    return unless value.match?(/[\r\n]/)

    errors.add(:value, "must be single line")
  end

  def secret_only_for_secret_config
    return unless env_config&.kind == "github_repository_environment_secrets"
    return if value_type == "secret"

    errors.add(:value_type, "must be secret for github repository environment secrets")
  end
end
