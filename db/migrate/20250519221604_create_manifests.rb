class CreateManifests < ActiveRecord::Migration[8.0]
  def change
    create_table :manifests do |t|
      t.string :url, null: false
      t.references :manifest_registry, null: false, foreign_key: true

      t.timestamps
    end

    add_index :manifests, :url, unique: true
  end
end
