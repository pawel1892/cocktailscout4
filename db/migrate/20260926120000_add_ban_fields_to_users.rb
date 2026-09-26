class AddBanFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :banned_at, :datetime
    add_column :users, :banned_until, :datetime
    add_column :users, :ban_reason, :text
    add_reference :users, :banned_by, foreign_key: { to_table: :users, on_delete: :nullify }

    add_index :users, :banned_at
  end
end
