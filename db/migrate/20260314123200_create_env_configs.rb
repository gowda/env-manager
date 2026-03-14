class CreateEnvConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :env_configs do |t|
      t.references :app_env, null: false, foreign_key: true
      t.string :kind, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :env_configs, [:app_env_id, :kind], unique: true
  end
end
