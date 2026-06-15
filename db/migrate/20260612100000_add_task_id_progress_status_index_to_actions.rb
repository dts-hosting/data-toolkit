class AddTaskIdProgressStatusIndexToActions < ActiveRecord::Migration[8.1]
  def change
    add_index :actions, [:task_id, :progress_status]
    remove_index :actions, :task_id, name: "index_actions_on_task_id"
  end
end
