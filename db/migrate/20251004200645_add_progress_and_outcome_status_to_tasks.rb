class AddProgressAndOutcomeStatusToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :progress_status, :string, default: "pending", null: false
    add_column :tasks, :outcome_status, :string
    add_index :tasks, :progress_status
    add_index :tasks, :outcome_status
  end
end
