class AddDataItemsCountToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :data_items_count, :integer, default: 0, null: false
  end
end
