class RecipeSuggestionIngredient < ApplicationRecord
  acts_as_list scope: :recipe_suggestion

  # Associations
  belongs_to :recipe_suggestion
  belongs_to :ingredient
  belongs_to :unit, optional: true

  # Validations
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :position, presence: true
end
