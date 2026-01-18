class Ingredient < ApplicationRecord
  has_many :collection_ingredients, dependent: :destroy
  has_many :ingredient_collections, through: :collection_ingredients
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true
  validates :alcoholic_content, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
