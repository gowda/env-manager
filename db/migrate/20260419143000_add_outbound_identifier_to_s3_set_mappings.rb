require "set"

class AddOutboundIdentifierToS3SetMappings < ActiveRecord::Migration[8.1]
  class MigrationEnvSet < ActiveRecord::Base
    self.table_name = "env_sets"
  end

  class MigrationS3SetMapping < ActiveRecord::Base
    self.table_name = "s3_set_mappings"
    belongs_to :env_set, class_name: "AddOutboundIdentifierToS3SetMappings::MigrationEnvSet", optional: true
  end

  def up
    add_column :s3_set_mappings, :outbound_identifier, :string

    backfill_outbound_identifiers_from_env_set_name!
  end

  def down
    remove_column :s3_set_mappings, :outbound_identifier
  end

  private

  def backfill_outbound_identifiers_from_env_set_name!
    used_identifiers_by_pattern = Hash.new { |hash, key| hash[key] = Set.new }

    existing_scope = MigrationS3SetMapping
      .where(match_kind: "prefix")
      .where.not(outbound_identifier: [nil, ""])

    existing_scope.pluck(:key_pattern, :outbound_identifier).each do |key_pattern, identifier|
      used_identifiers_by_pattern[key_pattern] << identifier
    end

    missing_scope = MigrationS3SetMapping
      .where(match_kind: "prefix", outbound_identifier: nil)
      .includes(:env_set)
      .order(:key_pattern, :id)

    missing_scope.each do |mapping|
      base_identifier = normalized_identifier_for(mapping.env_set&.name)
      identifier = next_available_identifier(base_identifier, used_identifiers_by_pattern[mapping.key_pattern])
      mapping.update_columns(outbound_identifier: identifier)
      used_identifiers_by_pattern[mapping.key_pattern] << identifier
    end
  end

  def normalized_identifier_for(name)
    slug = name.to_s.parameterize(separator: "-")
    slug.present? ? slug : "env-set"
  end

  def next_available_identifier(base_identifier, used_identifiers)
    return base_identifier unless used_identifiers.include?(base_identifier)

    suffix = 2
    loop do
      candidate = "#{base_identifier}-#{suffix}"
      return candidate unless used_identifiers.include?(candidate)

      suffix += 1
    end
  end
end
