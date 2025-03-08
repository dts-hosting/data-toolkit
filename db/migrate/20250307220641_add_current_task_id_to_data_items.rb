class AddCurrentTaskIdToDataItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :data_items, :current_task, null: false, foreign_key: { to_table: :tasks }
  end
end
