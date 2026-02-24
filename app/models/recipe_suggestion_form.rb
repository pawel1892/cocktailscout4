class RecipeSuggestionForm
  include ActiveModel::Model

  attr_accessor :recipe_suggestion, :user, :title, :description, :tag_list, :ingredients_data

  validates :title, presence: true
  validates :description, presence: true
  validates :user, presence: true
  validate :validate_ingredients

  def initialize(attributes = {})
    @recipe_suggestion = attributes[:recipe_suggestion] || RecipeSuggestion.new
    @user = attributes[:user]
    @title = attributes[:title] || @recipe_suggestion.title
    @description = attributes[:description] || @recipe_suggestion.description
    @tag_list = attributes[:tag_list] || @recipe_suggestion.tag_list
    @ingredients_data = attributes[:ingredients_data] || []
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Update or create recipe suggestion
      recipe_suggestion.user ||= user
      recipe_suggestion.title = title
      recipe_suggestion.description = description
      recipe_suggestion.tag_list = tag_list
      recipe_suggestion.status = "pending"  # Always reset to pending on save (for resubmissions)

      recipe_suggestion.save!

      # Remove old ingredients and create new ones
      recipe_suggestion.recipe_suggestion_ingredients.destroy_all

      # Create new ingredients with positions
      ingredients_data.each_with_index do |ingredient_data, index|
        create_recipe_suggestion_ingredient(ingredient_data, index + 1)
      end

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def persisted?
    recipe_suggestion.persisted?
  end

  private

  def validate_ingredients
    if ingredients_data.blank? || ingredients_data.size < 2
      errors.add(:ingredients, "Es müssen mindestens 2 Zutaten angegeben werden")
      return
    end

    ingredients_data.each_with_index do |ingredient_data, index|
      if ingredient_data[:ingredient_id].blank? && ingredient_data[:ingredient_name].blank?
        errors.add(:ingredients, "Zutat #{index + 1}: Name fehlt")
      end

      if ingredient_data[:amount].present?
        amount = ingredient_data[:amount].to_f
        if amount < 0
          errors.add(:ingredients, "Zutat #{index + 1}: Menge muss >= 0 sein")
        end
      end
    end
  end

  def create_recipe_suggestion_ingredient(ingredient_data, position)
    # Find or create ingredient
    ingredient = if ingredient_data[:ingredient_id].present?
      Ingredient.find(ingredient_data[:ingredient_id])
    elsif ingredient_data[:ingredient_name].present?
      Ingredient.find_or_create_by!(name: ingredient_data[:ingredient_name]) do |ing|
        ing.alcoholic_content = 0.0  # Default to 0.0 for new ingredients
      end
    else
      raise "Ingredient name or id required"
    end

    # Find unit if provided
    unit = ingredient_data[:unit_id].present? ? Unit.find(ingredient_data[:unit_id]) : nil

    # Create recipe suggestion ingredient
    recipe_suggestion.recipe_suggestion_ingredients.create!(
      ingredient: ingredient,
      unit: unit,
      amount: ingredient_data[:amount].present? ? ingredient_data[:amount].to_f : nil,
      additional_info: ingredient_data[:additional_info],
      display_name: ingredient_data[:display_name],
      is_optional: ingredient_data[:is_optional] == true || ingredient_data[:is_optional] == "true",
      is_scalable: ingredient_data[:is_scalable] != false && ingredient_data[:is_scalable] != "false",
      position: position
    )
  end
end
