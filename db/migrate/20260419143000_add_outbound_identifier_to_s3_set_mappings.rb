class AddOutboundIdentifierToS3SetMappings < ActiveRecord::Migration[8.1]
  def up
    add_column :s3_set_mappings, :outbound_identifier, :string

    execute <<~SQL
      UPDATE s3_set_mappings
      SET outbound_identifier = env_set_id::text
      WHERE match_kind = 'prefix' AND outbound_identifier IS NULL
    SQL
  end

  def down
    remove_column :s3_set_mappings, :outbound_identifier
  end
end
