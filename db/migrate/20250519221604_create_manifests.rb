class CreateManifests < ActiveRecord::Migration[8.0]
  def change
    create_table :manifests do |t|
      t.string :url, null: false, unique: true
      t.references :manifest_registry, null: false, foreign_key: true

      t.timestamps
    end
  end
end
