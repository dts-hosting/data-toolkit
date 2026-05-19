class AddCspaceProfileVersionOverridesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cspace_profile_override, :string
    add_column :users, :cspace_ui_version_override, :string
  end
end
