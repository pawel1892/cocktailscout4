module Legacy
  class UserIngredient < LegacyRecord
    self.table_name = "user_ingredients"

    belongs_to :user, class_name: "Legacy::User"
    belongs_to :ingredient, class_name: "Legacy::Ingredient"
  end
end
