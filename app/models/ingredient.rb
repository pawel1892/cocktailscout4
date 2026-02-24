class Ingredient < ApplicationRecord
  has_many :collection_ingredients, dependent: :destroy
  has_many :ingredient_collections, through: :collection_ingredients
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true
  validates :alcoholic_content, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Set default alcoholic_content to 0 if not provided
  before_validation :set_default_alcoholic_content

  # Scopes for filtering
  scope :unused, -> {
    left_joins(:recipe_ingredients)
      .group("ingredients.id")
      .having("COUNT(recipe_ingredients.id) = 0")
  }

  scope :used, -> {
    joins(:recipe_ingredients).distinct
  }

  scope :alcoholic, -> { where("alcoholic_content > 0") }

  scope :non_alcoholic, -> { where("alcoholic_content = 0") }

  # Check if ingredient is used in any recipes
  def in_use?
    recipe_ingredients.exists?
  end

  # Check if ingredient can be safely deleted
  def can_delete?
    !in_use?
  end

  # Get count of recipes using this ingredient
  def recipes_count
    recipes.distinct.count
  end

  # Safety guard in destroy method
  def destroy
    if in_use?
      errors.add(:base, "Zutat kann nicht gelöscht werden, da sie in #{recipes_count} Rezept(en) verwendet wird.")
      return false
    end
    super
  end

  private

  def set_default_alcoholic_content
    self.alcoholic_content ||= 0
  end
end
