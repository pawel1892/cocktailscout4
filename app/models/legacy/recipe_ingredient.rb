class Legacy::RecipeIngredient < LegacyRecord
  self.table_name = "recipe_ingredients"

  belongs_to :recipe, class_name: "Legacy::Recipe"
  belongs_to :ingredient, class_name: "Legacy::Ingredient"
end
