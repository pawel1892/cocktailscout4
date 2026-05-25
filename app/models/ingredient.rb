class Ingredient < ApplicationRecord
  has_many :collection_ingredients, dependent: :destroy
  has_many :ingredient_collections, through: :collection_ingredients
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients
  has_many :recipe_suggestion_ingredients, dependent: :destroy
  has_many :recipe_suggestions, through: :recipe_suggestion_ingredients

  has_many :ingredient_wiki_articles, dependent: :destroy
  has_many :wiki_articles, through: :ingredient_wiki_articles

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

  scope :used_in_visible_recipes, -> {
    joins(recipe_ingredients: :recipe).merge(Recipe.visible).distinct
  }

  scope :alcoholic, -> { where("alcoholic_content > 0") }

  scope :non_alcoholic, -> { where("alcoholic_content = 0") }

  # Check if ingredient is used in any non-deleted recipes or pending/approved suggestions
  def in_use?
    recipes.exists? || recipe_suggestions.where(status: %w[pending approved]).exists?
  end

  # Check if ingredient can be safely deleted
  def can_delete?
    !in_use?
  end

  # Get count of recipes and suggestions using this ingredient
  def recipes_count
    recipes.distinct.count
  end

  def suggestions_count
    recipe_suggestions.where(status: %w[pending approved]).count
  end

  # Safety guard in destroy method
  def destroy
    if in_use?
      parts = []
      parts << "#{recipes_count} Rezept(en)" if recipes_count > 0
      parts << "#{suggestions_count} Vorschlag(en)" if suggestions_count > 0
      errors.add(:base, "Zutat kann nicht gelöscht werden, da sie in #{parts.join(" und ")} verwendet wird.")
      return false
    end
    super
  end

  private

  def set_default_alcoholic_content
    self.alcoholic_content ||= 0
  end
end
