class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :favoritable, polymorphic: true, null: false
      t.integer :old_id
      t.index :old_id

      t.timestamps
    end
  end
end
