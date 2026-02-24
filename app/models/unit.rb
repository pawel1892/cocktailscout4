class Unit < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true, unless: -> { name == "x" }
  validates :plural_name, presence: true, unless: -> { name == "x" }
  validates :category, inclusion: { in: %w[volume count special] }
  validates :ml_ratio, numericality: { greater_than: 0 }, if: -> { category.in?(%w[volume special]) }

  # Scopes for filtering
  scope :unused, -> {
    left_joins(:recipe_ingredients)
      .group("units.id")
      .having("COUNT(recipe_ingredients.id) = 0")
  }

  scope :used, -> {
    joins(:recipe_ingredients).distinct
  }

  scope :by_category, ->(category) {
    where(category: category) if category.present?
  }

  scope :volume_units, -> { where(category: "volume") }
  scope :count_units, -> { where(category: "count") }
  scope :special_units, -> { where(category: "special") }

  # Check if unit is used in any recipe ingredients
  def in_use?
    recipe_ingredients.exists?
  end

  # Check if unit can be safely deleted
  def can_delete?
    !in_use?
  end

  # Get count of recipe ingredients using this unit
  def recipe_ingredients_count
    recipe_ingredients.count
  end

  # Safety guard in destroy method
  def destroy
    if in_use?
      errors.add(:base, "Einheit kann nicht gelöscht werden, da sie in #{recipe_ingredients_count} Rezeptzutat(en) verwendet wird.")
      return false
    end
    super
  end

  def to_ml(amount)
    return nil unless ml_ratio.present?
    amount * ml_ratio
  end

  def from_ml(ml_amount)
    return nil unless ml_ratio.present?
    ml_amount / ml_ratio
  end

  # Get correct plural/singular form based on amount
  def display_name_for(amount)
    return plural_name if amount != 1 && plural_name.present?
    display_name
  end
end
