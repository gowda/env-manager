class DropVariables < ActiveRecord::Migration[8.1]
  def up
    drop_table :variables
  end

  def down
    create_table :variables do |t|
      t.string :key
      t.string :value
      t.string :type
      t.timestamps
    end
  end
end
