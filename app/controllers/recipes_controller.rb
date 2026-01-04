class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    @recipes = Recipe.all
  end

  def show
    @recipe = Recipe.includes(recipe_ingredients: :ingredient, recipe_comments: :user).find_by!(slug: params[:id])
  end
end