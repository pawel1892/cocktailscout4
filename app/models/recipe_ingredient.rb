class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient
  belongs_to :unit, optional: true  # Optional during migration

  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  acts_as_list scope: :recipe

  # Update recipe's computed fields when ingredients change
  after_save :update_recipe_computed_fields
  after_destroy :update_recipe_computed_fields

  def amount_in_ml
    return nil unless unit&.ml_ratio && amount
    unit.to_ml(amount)
  end

  def formatted_amount
    return additional_info if additional_info.present? && amount.nil?
    return nil unless amount && unit

    # Format the amount (with fraction support for blank unit)
    formatted = if unit.name == "x"
      format_fraction(amount)
    else
      format_german_number(amount)
    end

    unit_name = unit.display_name_for(amount)
    "#{formatted}#{" " unless unit_name.empty?}#{unit_name}"
  end

  def formatted_ingredient_name
    # Use plural form when amount > 1 and unit is blank
    if unit&.name == "x" && amount && amount > 1 && ingredient.plural_name.present?
      ingredient.plural_name
    else
      ingredient.name
    end
  end

  # Check if ingredient can be scaled
  def scalable?
    amount.present? && unit.present? && !needs_review
  end

  # Get display text (structured or fallback to description)
  def display_text
    if scalable?
      "#{formatted_amount} #{formatted_ingredient_name}"
    else
      old_description  # Fallback to original text
    end
  end

  def scale(factor)
    return self if amount.nil?
    return self if is_garnish?  # Garnishes don't scale!
    return self if needs_review  # Don't scale uncertain ingredients

    scaled_amount = amount * factor

    # Round if unit is non-divisible (Spritzer, Dash, etc.)
    if unit && !unit.divisible
      scaled_amount = scaled_amount.round
    end

    dup.tap { |ri| ri.amount = scaled_amount }
  end

  private

  def update_recipe_computed_fields
    recipe.reload.update_computed_fields! if recipe
  end

  def format_german_number(number)
    # Format number in German style: comma for decimal separator
    # Integer amounts without decimals, decimal amounts with comma
    if number % 1 == 0
      number.to_i.to_s
    else
      number.to_s.sub(".", ",")
    end
  end

  def format_fraction(decimal)
    whole = decimal.to_i
    fraction = decimal - whole

    return whole.to_s if fraction.zero?

    # Common fractions
    fraction_map = {
      0.125 => "1/8",
      0.166666667 => "1/6",
      0.25 => "1/4",
      0.333333333 => "1/3",
      0.5 => "1/2",
      0.666666667 => "2/3",
      0.75 => "3/4"
    }

    fraction_str = fraction_map.find { |k, v| (k - fraction).abs < 0.01 }&.last || fraction.to_s

    if whole.zero?
      fraction_str
    else
      "#{whole} #{fraction_str}"
    end
  end
end
