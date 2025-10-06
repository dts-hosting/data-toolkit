class RemoveStatusFromTasks < ActiveRecord::Migration[8.0]
  def change
    remove_column :tasks, :status, :string
  end
end
