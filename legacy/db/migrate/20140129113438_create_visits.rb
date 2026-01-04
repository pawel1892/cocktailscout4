class CreateVisits < ActiveRecord::Migration
  def change
    create_table :visits do |t|
      t.integer :visitable_id
      t.string :visitable_type
      t.integer :user_id
      t.integer :total_visits, default: 0
      t.datetime :last_visit_time

      t.timestamps
    end
  end
end
