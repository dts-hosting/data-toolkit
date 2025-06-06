class UpdateUniqueDataConfigAttributes < ActiveRecord::Migration[8.0]
  def change
    remove_index :data_configs, name: "unique_data_config_attributes"
    add_index :data_configs, [:manifest_id, :config_type, :profile, :version, :record_type],
      unique: true,
      name: "unique_data_config_attributes"
  end
end
