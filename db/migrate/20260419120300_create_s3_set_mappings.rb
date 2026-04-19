class CreateS3SetMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :s3_set_mappings do |t|
      t.references :env_set, null: false, foreign_key: true
      t.string :key_pattern, null: false
      t.string :match_kind, null: false, default: "exact"
      t.boolean :sync_enabled, null: false, default: true
      t.string :last_synced_checksum
      t.string :last_sync_origin
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :s3_set_mappings, [:match_kind, :key_pattern]
  end
end
