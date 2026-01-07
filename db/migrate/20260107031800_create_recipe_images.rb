class CreateRecipeImages < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_images do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.integer :old_id, index: true

      t.timestamps
    end
  end
end
