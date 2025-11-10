class AddUpdatedAtIndexToActivities < ActiveRecord::Migration[8.0]
  def change
    add_index :activities, :updated_at
  end
end
