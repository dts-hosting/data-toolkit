class CreateActions < ActiveRecord::Migration[8.0]
  def change
    create_table :actions do |t|
      t.references :task, null: false, foreign_key: true
      t.references :data_item, null: false, foreign_key: true
      t.json :feedback
      t.string :progress_status, default: "pending", null: false
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :actions, :progress_status
    add_index :actions, [:task_id, :data_item_id], unique: true
    add_index :actions, [:data_item_id, :task_id]
  end
end
