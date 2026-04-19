class RenameHasValueToValuePresentInEnvItems < ActiveRecord::Migration[8.0]
  def change
    rename_column :env_items, :has_value, :value_present
  end
end
