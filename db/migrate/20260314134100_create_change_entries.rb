class CreateChangeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :change_entries do |t|
      t.references :change_set, null: false, foreign_key: true
      t.string :key, null: false
      t.string :operation, null: false
      t.string :previous_value_type
      t.string :new_value_type
      t.boolean :secret, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :change_entries, [:change_set_id, :key]
  end
end
