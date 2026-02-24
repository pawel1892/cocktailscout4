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
    return nil unless amount

    if unit_id
      # Case 1: Zutat mit expliziter Einheit (z.B. "4 cl Rum")
      unit.ml_ratio ? (amount * unit.ml_ratio) : nil
    elsif ingredient&.ml_per_unit
      # Case 2: Zutat ohne Einheit mit definiertem Volumen (z.B. "2 Limetten")
      amount * ingredient.ml_per_unit
    else
      # Case 3: Zutat ohne Einheit und ohne Volumendefinition (z.B. "1 Minzweig")
      nil
    end
  end

  def formatted_amount
    return additional_info if additional_info.present? && amount.nil?
    return nil unless amount

    # Format the amount (with fraction support for ingredients without explicit unit)
    if unit.nil?
      # No unit (e.g., "1 Limette", "2 Orangen") - use fraction format
      format_fraction(amount)
    else
      # Has unit - use German number format
      formatted = format_german_number(amount)
      unit_name = unit.display_name_for(amount)
      "#{formatted}#{" " unless unit_name.empty?}#{unit_name}"
    end
  end

  def formatted_ingredient_name
    # Use custom display_name if set
    return display_name if display_name.present?

    # Use plural form when amount > 1 and there's no explicit unit
    if unit.nil? && amount && amount > 1 && ingredient.plural_name.present?
      ingredient.plural_name
    else
      ingredient.name
    end
  end

  # Check if ingredient can be scaled
  def scalable?
    amount.present? && !needs_review && is_scalable
  end

  # Get display text (structured or fallback to description)
  def display_text
    if scalable?
      "#{formatted_amount} #{formatted_ingredient_name}"
    elsif !is_scalable && display_name.present?
      [ formatted_amount, formatted_ingredient_name ].compact.join(" ")
    else
      old_description  # Fallback to original text
    end
  end

  def scale(factor)
    return self if amount.nil?
    return self unless is_scalable  # Non-scalable ingredients don't scale!
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
