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

    render json: scaled_ingredients
  end

  private

  def set_recipe
    @recipe = Recipe.includes(recipe_ingredients: [ :ingredient, :unit ])
                    .find_by!(slug: params[:recipe_slug])
  end
end
