class RecipeIngredientsController < ApplicationController
  allow_unauthenticated_access only: [ :index ]
  before_action :set_recipe

  def index
    scale_factor = params[:scale]&.to_f || 1.0

    scaled_ingredients = @recipe.recipe_ingredients.includes(:ingredient, :unit).map do |ri|
      scaled = ri.scale(scale_factor)
      {
        id: ri.id,
        amount: scaled.amount,
        unit_name: ri.unit&.name,
        unit_display_name: ri.unit&.display_name,
        ingredient_name: scaled.formatted_ingredient_name,
        ingredient_plural_name: ri.ingredient.plural_name,
        formatted_amount: scaled.formatted_amount,
        additional_info: ri.additional_info,
        is_garnish: ri.is_garnish
      }
    end

    # Calculate scaled alcohol info
    total_volume = @recipe.total_volume_in_ml * scale_factor
    alcohol_volume = @recipe.alcohol_volume_in_ml * scale_factor
    alcohol_content = @recipe.calculate_alcohol_content

    render json: {
      ingredients: scaled_ingredients,
      alcohol_info: {
        total_volume_ml: total_volume.round(1),
        alcohol_volume_ml: alcohol_volume.round(1),
        alcohol_content_percent: alcohol_content
      }
    }
  end

  private

  def set_recipe
    @recipe = Recipe.includes(recipe_ingredients: [ :ingredient, :unit ])
                    .find_by!(slug: params[:recipe_slug])
  end
end
