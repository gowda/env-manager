class CreateEnvSets < ActiveRecord::Migration[8.1]
  def change
    create_table :env_sets do |t|
      t.references :app_env, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false
      t.boolean :ui_editable, null: false, default: true
      t.bigint :cloned_from_version_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :env_sets, [:app_env_id, :name], unique: true
    add_index :env_sets, :cloned_from_version_id
  end
end
