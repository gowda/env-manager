class CreateChangeSets < ActiveRecord::Migration[8.1]
  def change
    create_table :change_sets do |t|
      t.references :env_config, null: false, foreign_key: true
      t.text :reason, null: false
      t.string :status, null: false, default: "applied"

      t.timestamps
    end
  end
end
