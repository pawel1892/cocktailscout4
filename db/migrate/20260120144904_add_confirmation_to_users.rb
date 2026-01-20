class AddConfirmationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_at, :datetime, after: :sign_in_count
    add_column :users, :confirmation_sent_at, :datetime, after: :confirmed_at
    add_column :users, :confirmation_token, :string, after: :confirmation_sent_at

    add_index :users, :confirmation_token, unique: true

    reversible do |dir|
      dir.up { User.update_all(confirmed_at: Time.current) }
    end
  end
end
