class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  helper_method :sort_column, :sort_direction

  def index
    query = Recipe.includes(:user, :taggings, :tags)

    # Handle specific join sorting
    query = query.left_joins(:user) if sort_column == "users.username"

    @pagy, @recipes = pagy(query.order("#{sort_column} #{sort_direction}"))
  end

  def show
    @recipe = Recipe.includes(recipe_ingredients: :ingredient, recipe_comments: :user).find_by!(slug: params[:id])
  end

  private

  def sort_column
    %w[title average_rating alcohol_content views users.username].include?(params[:sort]) ? params[:sort] : "views"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
