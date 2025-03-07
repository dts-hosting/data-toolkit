class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :type, null: false
      t.references :activity, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :tasks, :status
  end
end
