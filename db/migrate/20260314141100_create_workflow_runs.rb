class CreateWorkflowRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_runs do |t|
      t.references :env_config, null: false, foreign_key: true
      t.references :workflow_definition, null: false, foreign_key: true
      t.references :change_set, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.string :trigger_source, null: false
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :workflow_runs, [:env_config_id, :created_at]
  end
end
