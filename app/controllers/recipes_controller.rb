class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  helper_method :sort_column, :sort_direction

  def index
    query = Recipe.includes(:user, :taggings, :tags, approved_recipe_images: { image_attachment: :blob })

    # Handle specific join sorting
    query = query.left_joins(:user) if sort_column == "users.username"

    @pagy, @recipes = pagy(query.order("#{sort_column} #{sort_direction}"))
  end

  def show
    @recipe = Recipe.includes(
      :taggings,
      :tags,
      recipe_ingredients: :ingredient,
      approved_recipe_images: { image_attachment: :blob }
    ).find_by!(slug: params[:id])

    @comments_pagy, @comments = pagy(
      @recipe.recipe_comments.includes(:user).order(created_at: :desc),
      limit: 30,
      page_key: "comments"
    )

    @recipe.track_visit(Current.user)
  end

  private

  def sort_column
    %w[title average_rating alcohol_content visits_count users.username].include?(params[:sort]) ? params[:sort] : "visits_count"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
