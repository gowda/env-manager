class CreateEnvironmentVariables < ActiveRecord::Migration[8.1]
  def change
    create_table :environment_variables do |t|
      t.references :env_config, null: false, foreign_key: true
      t.string :key, null: false
      t.text :value, null: false
      t.string :value_type, null: false, default: "single_line"

      t.timestamps
    end

    add_index :environment_variables, [:env_config_id, :key], unique: true
  end
end
