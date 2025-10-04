class RemoveFieldsFromDataItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :data_items, :status, :string
    remove_column :data_items, :feedback, :json
    remove_column :data_items, :current_task_id, :integer
    remove_column :data_items, :started_at, :datetime
    remove_column :data_items, :completed_at, :datetime
  end
end
