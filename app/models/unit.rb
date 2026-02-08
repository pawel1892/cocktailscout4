class Unit < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true, unless: -> { name == "x" }
  validates :plural_name, presence: true, unless: -> { name == "x" }
  validates :category, inclusion: { in: %w[volume count special] }
  validates :ml_ratio, numericality: { greater_than: 0 }, if: -> { category.in?(%w[volume special]) }

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
