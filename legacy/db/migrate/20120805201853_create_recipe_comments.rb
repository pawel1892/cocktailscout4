class CreateRecipeComments < ActiveRecord::Migration
  def change
    create_table :recipe_comments do |t|
      t.integer :user_id
      t.integer :recipe_id
      t.text :comment
      t.string :ip

      t.timestamps
    end
  end
end
