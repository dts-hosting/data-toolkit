class CreateManifestRegistries < ActiveRecord::Migration[8.0]
  def change
    create_table :manifest_registries do |t|
      t.string :url, null: false
      t.date :last_updated_at

      t.timestamps
    end

    add_index :manifest_registries, :url, unique: true
  end
end
