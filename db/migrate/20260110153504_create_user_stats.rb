class CreateUserStats < ActiveRecord::Migration[8.1]
  def change
    create_table :user_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :points, null: false, default: 0

      t.timestamps
    end
  end
end
