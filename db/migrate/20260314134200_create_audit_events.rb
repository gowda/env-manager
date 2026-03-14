class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :env_config, null: false, foreign_key: true
      t.references :change_set, foreign_key: true
      t.string :action, null: false
      t.string :message, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_events, [:env_config_id, :created_at]
  end
end
