class CreateVariables < ActiveRecord::Migration[8.1]
  def change
    create_table :variables do |t|
      t.string :key
      t.string :value
      t.string :type

      t.timestamps
    end
  end
end
