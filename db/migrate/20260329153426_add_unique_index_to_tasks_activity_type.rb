class AddUniqueIndexToTasksActivityType < ActiveRecord::Migration[8.1]
  def change
    add_index :tasks, [:activity_id, :type], unique: true
  end
end
