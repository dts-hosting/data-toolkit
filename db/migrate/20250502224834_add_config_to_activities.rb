class AddConfigToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :config, :json, null: false, default: {}
  end
end
