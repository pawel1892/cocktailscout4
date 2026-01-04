class CreateUserRanks < ActiveRecord::Migration
  def change
    create_table :user_ranks do |t|
      t.integer :user_id
      t.integer :points

      t.timestamps
    end
  end
end
