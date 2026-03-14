class CreateWorkflowRunSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_run_steps do |t|
      t.references :workflow_run, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "queued"
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :workflow_run_steps, [:workflow_run_id, :name]
  end
end
