class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :visitable, polymorphic: true, null: false
      t.references :user, null: true, foreign_key: true
      t.integer :count, default: 0, null: false
      t.datetime :last_visited_at
      t.integer :old_id

      t.timestamps
    end
    add_index :visits, :old_id
    add_index :visits, [ :visitable_type, :visitable_id, :user_id ], unique: true, name: "index_visits_on_visitable_and_user_id"
  end
end
