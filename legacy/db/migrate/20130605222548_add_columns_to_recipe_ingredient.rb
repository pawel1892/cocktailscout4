class AddColumnsToRecipeIngredient < ActiveRecord::Migration
  def change
    add_column :recipe_ingredients, :cl_amount, :integer
    add_column :recipe_ingredients, :sequence, :integer
  end
end
