class AddLastSeenAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_seen_at, :datetime
    # Seed from last_active_at so existing users don't lose their history
    User.where.not(last_active_at: nil).update_all("last_seen_at = last_active_at")
  end
end
