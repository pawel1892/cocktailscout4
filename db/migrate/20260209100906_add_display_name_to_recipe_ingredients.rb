class AddDisplayNameToRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_ingredients, :display_name, :string
  end
end
