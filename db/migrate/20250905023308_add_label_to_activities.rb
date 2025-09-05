class AddLabelToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :label, :string, null: false
  end
end
