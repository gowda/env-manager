class CreateAppEnvs < ActiveRecord::Migration[8.1]
  def change
    create_table :app_envs do |t|
      t.references :app, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :app_envs, [:app_id, :name], unique: true
  end
end
