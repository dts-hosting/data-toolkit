class AddStatusAndFeedbackToDataItems < ActiveRecord::Migration[8.0]
  def change
    add_column :data_items, :status, :integer, null: false, default: 0
    add_column :data_items, :feedback, :json

    add_index :data_items, :status
  end
end
