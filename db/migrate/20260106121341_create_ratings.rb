class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :rateable, polymorphic: true, null: false
      t.integer :score, null: false
      t.integer :old_id, index: true

      t.timestamps
    end

    add_index :ratings, [ :user_id, :rateable_type, :rateable_id ], unique: true
  end
end
