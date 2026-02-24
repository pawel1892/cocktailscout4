class RecipeForm
  include ActiveModel::Model

  attr_accessor :recipe, :user, :title, :description, :tag_list, :ingredients_data, :is_public

  validates :title, presence: true
  validates :description, presence: true
  validates :user, presence: true
  validate :validate_ingredients

  def initialize(attributes = {})
    @recipe = attributes[:recipe] || Recipe.new
    @user = attributes[:user]
    @title = attributes[:title] || @recipe.title
    @description = attributes[:description] || @recipe.description
    @tag_list = attributes[:tag_list] || @recipe.tag_list.join(", ")
    # Use key? to check if is_public was explicitly set, otherwise use recipe's value or false
    @is_public = attributes.key?(:is_public) ? attributes[:is_public] : (@recipe.is_public || false)
    @ingredients_data = attributes[:ingredients_data] || []
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Update or create recipe
      recipe.user ||= user
      recipe.title = title
      recipe.description = description
      recipe.is_public = is_public

      # Generate slug if new record
      if recipe.new_record?
        recipe.slug = generate_slug(title)
      end

      recipe.save!

      # Update tags (acts-as-taggable-on requires save after setting tag_list)
      recipe.tag_list = tag_list
      recipe.save!

      # Remove old ingredients and create new ones
      recipe.recipe_ingredients.destroy_all

      # Create new ingredients with positions
      ingredients_data.each_with_index do |ingredient_data, index|
        create_recipe_ingredient(ingredient_data, index + 1)
      end

      # Update computed fields (total_volume, alcohol_content)
      recipe.reload.update_computed_fields!

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def persisted?
    recipe.persisted?
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

  def create_recipe_ingredient(ingredient_data, position)
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

    # Create recipe ingredient
    recipe.recipe_ingredients.create!(
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

  def generate_slug(title)
    # Simple slug generation - convert to lowercase, replace spaces with hyphens
    base_slug = title.parameterize

    # Ensure uniqueness
    slug = base_slug
    counter = 1
    while Recipe.exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug
  end
end
