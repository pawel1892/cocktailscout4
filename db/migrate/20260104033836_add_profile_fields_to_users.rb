class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index :users, :username
    add_column :users, :sign_in_count, :integer
    add_column :users, :last_active_at, :datetime
    add_column :users, :gender, :string
    add_column :users, :prename, :string
    add_column :users, :public_email, :string
    add_column :users, :homepage, :string
    add_column :users, :location, :string
    add_column :users, :title, :string
  end
end
