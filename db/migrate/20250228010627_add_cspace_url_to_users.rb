class AddCspaceUrlToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :cspace_url, :string, null: false
    add_column :users, :password, :string, null: false
    remove_column :users, :password_digest, :string
    add_index :users, [:email_address, :cspace_url], unique: true
    remove_index :users, :email_address if index_exists?(:users, :email_address)
  end
end
