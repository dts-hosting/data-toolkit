class AddActionCountersToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :actions_count, :integer, default: 0, null: false
    add_column :tasks, :actions_completed_count, :integer, default: 0, null: false
  end
end
