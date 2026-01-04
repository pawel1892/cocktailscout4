class Legacy::Recipe < LegacyRecord
  self.table_name = "recipes"
  
  belongs_to :user, class_name: "Legacy::User", optional: true
  has_many :recipe_ingredients, class_name: "Legacy::RecipeIngredient", foreign_key: "recipe_id"
end