class AddDailyLoginCountToUser < ActiveRecord::Migration
  def change
    add_column :users, :daily_login_count, :integer
  end
end
