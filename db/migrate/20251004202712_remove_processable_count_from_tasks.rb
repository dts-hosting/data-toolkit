class RemoveProcessableCountFromTasks < ActiveRecord::Migration[8.0]
  def change
    remove_column :tasks, :processable_count, :integer
  end
end
