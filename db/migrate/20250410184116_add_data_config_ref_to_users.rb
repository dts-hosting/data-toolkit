class AddDataConfigRefToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :data_config, null: true, foreign_key: true
  end
end
