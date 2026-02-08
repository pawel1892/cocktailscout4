class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  helper_method :sort_column, :sort_direction

  def index
    add_breadcrumb "Rezepte"
    set_meta_tags(
      title: "Cocktail-Rezepte",
      description: "Entdecke die besten Cocktail-Rezepte unserer Community. Filtere nach Bewertung, Zutaten und Tags."
    )
    query = Recipe.includes(:user, :taggings, :tags, approved_recipe_images: { image_attachment: :blob })

    # Filters
    query = query.search_by_title(params[:q])
    query = query.by_min_rating(params[:min_rating])
    query = query.by_ingredient(params[:ingredient_id])
    query = query.tagged_with(params[:tag]) if params[:tag].present?
    query = query.by_collection(params[:collection_id])

    # Filter by favorites
    if params[:filter] == "favorites" && authenticated?
      query = query.joins(:favorites).where(favorites: { user_id: Current.user.id })
    end

    # Filter data
    @tags = ActsAsTaggableOn::Tag.order(:name)
    @ingredients = Ingredient.order(:name)
    @collections = authenticated? ? Current.user.ingredient_collections.order(is_default: :desc, name: :asc) : []
    @selected_collection = @collections.find { |c| c.id == params[:collection_id].to_i } if params[:collection_id].present?

    # Handle specific join sorting
    query = query.left_joins(:user) if sort_column == "users.username"

    @pagy, @recipes = pagy(query.order("#{sort_column} #{sort_direction}"))
    @favorite_recipe_ids = Current.user ? Current.user.favorites.where(favoritable_type: "Recipe", favoritable_id: @recipes.map(&:id)).pluck(:favoritable_id) : []
  end

  def show
    @recipe = Recipe.includes(
      :taggings,
      :tags,
      recipe_ingredients: :ingredient,
      approved_recipe_images: [ :user, { image_attachment: :blob } ]
    ).find_by!(slug: params[:slug])

    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb @recipe.title
    set_recipe_meta_tags(@recipe)

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
