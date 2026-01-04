class CreateUserRecipes < ActiveRecord::Migration
  def change
    create_table :user_recipes do |t|
      t.integer :recipe_id
      t.integer :user_id
      t.string :list

      t.timestamps
    end
  end
end
