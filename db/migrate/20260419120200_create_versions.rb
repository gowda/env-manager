class CreateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :versions do |t|
      t.string :whodunnit
      t.string :event, null: false
      t.string :item_type, null: false
      t.bigint :item_id, null: false
      t.text :object
      t.text :object_changes
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at
    end

    add_index :versions, [:item_type, :item_id]
    add_index :versions, :created_at
  end
end
