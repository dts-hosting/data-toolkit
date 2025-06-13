class AddDataConfigsCountToManifests < ActiveRecord::Migration[8.0]
  def change
    add_column :manifests, :data_configs_count, :integer, default: 0, null: false
  end
end
