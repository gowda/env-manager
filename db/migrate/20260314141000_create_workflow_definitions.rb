class CreateWorkflowDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_definitions do |t|
      t.references :env_config, null: false, foreign_key: true
      t.string :kind, null: false
      t.boolean :enabled, null: false, default: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :workflow_definitions, [:env_config_id, :kind]
  end
end
