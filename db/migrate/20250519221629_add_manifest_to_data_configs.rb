class AddManifestToDataConfigs < ActiveRecord::Migration[8.0]
  def change
    add_reference :data_configs, :manifest, null: false, foreign_key: true
  end
end
