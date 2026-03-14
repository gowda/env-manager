class CreateApps < ActiveRecord::Migration[8.1]
  def change
    create_table :apps do |t|
      t.string :name, null: false
      t.text :description
      t.string :github_repository, null: false
      t.string :url

      t.timestamps
    end

    add_index :apps, :name, unique: true
  end
end
