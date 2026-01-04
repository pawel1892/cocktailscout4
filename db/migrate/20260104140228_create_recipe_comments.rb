class CreateRecipeComments < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_comments do |t|
      t.references :user, null: true, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.text :body
      t.integer :old_id, index: true

      t.timestamps
    end
  end
end
