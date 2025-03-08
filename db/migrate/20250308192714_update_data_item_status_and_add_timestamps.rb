class UpdateDataItemStatusAndAddTimestamps < ActiveRecord::Migration[8.0]
  def change
    add_column :data_items, :started_at, :datetime
    add_column :data_items, :completed_at, :datetime
  end
end
