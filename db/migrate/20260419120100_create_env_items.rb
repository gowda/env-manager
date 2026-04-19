class CreateEnvItems < ActiveRecord::Migration[8.1]
  def change
    create_table :env_items do |t|
      t.references :env_set, null: false, foreign_key: true
      t.string :key, null: false
      t.text :value
      t.string :value_type, null: false, default: "string"
      t.boolean :has_value, null: false, default: true

      t.timestamps
    end

    add_index :env_items, [:env_set_id, :key], unique: true
  end
end
