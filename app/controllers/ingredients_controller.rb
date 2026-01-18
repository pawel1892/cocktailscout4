class IngredientsController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  def index
    @ingredients = Ingredient.left_joins(:recipe_ingredients)
      .select("ingredients.*, COUNT(DISTINCT recipe_ingredients.recipe_id) as recipes_count")
      .group("ingredients.id")

    if params[:q].present?
      @ingredients = @ingredients.where("ingredients.name LIKE ?", "%#{params[:q]}%")
    end

    @ingredients = @ingredients.order(:name)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          ingredients: @ingredients.map { |i|
            {
              id: i.id,
              name: i.name,
              recipes_count: i.recipes_count.to_i
            }
          }
        }
      end
    end
  end
end
