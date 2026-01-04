class Userlogin < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :login, :string, null: false, collation: :utf8_bin
  end
end
