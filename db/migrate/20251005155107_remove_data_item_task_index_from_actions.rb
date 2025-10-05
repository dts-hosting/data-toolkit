class RemoveDataItemTaskIndexFromActions < ActiveRecord::Migration[8.0]
  def change
    remove_index :actions, column: [:data_item_id, :task_id], name: "index_actions_on_data_item_id_and_task_id"
  end
end
