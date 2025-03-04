class CreateDataConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :data_configs do |t|
      t.string :config_type, null: false
      t.string :profile, null: false
      t.string :version
      t.string :record_type
      t.string :url, null: false

      t.timestamps

      t.index [:config_type, :profile, :version, :record_type],
        unique: true,
        name: "unique_data_config_attributes"
    end
  end
end
