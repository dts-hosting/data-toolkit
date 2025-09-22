class CreateHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :histories do |t|
      t.string :activity_user, null: false
      t.string :activity_url, null: false
      t.string :activity_type, null: false
      t.string :activity_label, null: false
      t.datetime :activity_created_at, null: false
      t.string :task_type, null: false
      t.string :task_status, null: false
      t.json :task_feedback
      t.datetime :task_started_at
      t.datetime :task_completed_at

      t.timestamps
    end
    add_index :histories, :activity_user
    add_index :histories, :activity_url
  end
end
