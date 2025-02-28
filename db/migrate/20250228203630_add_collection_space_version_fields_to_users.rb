class AddCollectionSpaceVersionFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :cspace_api_version, :string, null: false
    add_column :users, :cspace_profile, :string, null: false
    add_column :users, :cspace_ui_version, :string, null: false
  end
end
