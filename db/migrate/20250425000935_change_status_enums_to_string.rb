class ChangeStatusEnumsToString < ActiveRecord::Migration[8.0]
  def up
    change_column :data_items, :status, :string, null: false, default: "pending"
    change_column :tasks, :status, :string, null: false, default: "pending"
  end

  def down
    change_column :data_items, :status, :integer, null: false, default: 0
    change_column :tasks, :status, :integer, null: false, default: 0
  end
end
