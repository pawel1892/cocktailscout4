class IngredientCollection < ApplicationRecord
  belongs_to :user
  has_many :collection_ingredients, dependent: :destroy
  has_many :ingredients, through: :collection_ingredients

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :name, length: { minimum: 1, maximum: 100 }

  before_validation :set_default_name, on: :create
  after_create :set_as_default_if_first

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :default, -> { where(is_default: true) }

  # Find which recipes can be made with this collection's ingredients
  def doable_recipes
    ingredient_ids = ingredients.pluck(:id)
    return Recipe.none if ingredient_ids.empty?

    # Find recipes where all required ingredients are in our collection
    Recipe.joins(:recipe_ingredients)
      .group("recipes.id")
      .having(
        "COUNT(DISTINCT recipe_ingredients.ingredient_id) = " \
        "COUNT(DISTINCT CASE WHEN recipe_ingredients.ingredient_id IN (?) THEN recipe_ingredients.ingredient_id END)",
        ingredient_ids
      )
  end

  private

  def set_default_name
    self.name ||= "My Collection"
  end

  def set_as_default_if_first
    update_column(:is_default, true) if user.ingredient_collections.count == 1
  end
end
