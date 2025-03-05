class CreateDataItems < ActiveRecord::Migration[8.0]
  def change
    create_table :data_items do |t|
      t.json :data, null: false
      t.integer :position, null: false, default: 0
      t.references :activity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :data_items, [:activity_id, :position], unique: true
  end
end
