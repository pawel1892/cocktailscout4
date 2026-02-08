class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient
  belongs_to :unit, optional: true  # Optional during migration

  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  acts_as_list scope: :recipe

  def amount_in_ml
    return nil unless unit&.ml_ratio && amount
    unit.to_ml(amount)
  end

  def formatted_amount
    return additional_info if additional_info.present? && amount.nil?
    return nil unless amount && unit

    formatted = amount % 1 == 0 ? amount.to_i : amount
    unit_name = unit.display_name_for(amount)
    "#{formatted} #{unit_name}"
  end

  def scale(factor)
    return self if amount.nil?
    return self if is_garnish?  # Garnishes don't scale!

    dup.tap { |ri| ri.amount = amount * factor }
  end
end
