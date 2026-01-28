class AddAutoAdvancedToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :auto_advance, :boolean, default: true
  end
end
