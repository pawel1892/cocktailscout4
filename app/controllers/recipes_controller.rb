class RecipesController < ApplicationController
  include RecipesHelper
  allow_unauthenticated_access only: %i[ index show ]
  before_action :require_recipe_moderator!, only: %i[ new create ]
  before_action :set_recipe, only: %i[ show edit update destroy publish ]
  before_action :authorize_view!, only: %i[ show ]
  before_action :authorize_edit!, only: %i[ edit update publish ]
  before_action :authorize_delete!, only: %i[ destroy ]
  helper_method :sort_column, :sort_direction

  def index
    add_breadcrumb "Rezepte"
    set_meta_tags(
      title: "Cocktail-Rezepte",
      description: "Entdecke die besten Cocktail-Rezepte unserer Community. Filtere nach Bewertung, Zutaten und Tags."
    )
    query = Recipe.visible.includes(:user, :taggings, :tags, approved_recipe_images: { image_attachment: :blob })

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

  def new
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb "Neues Rezept"

    @recipe_form_data = {
      title: "",
      description: "",
      tagList: "",
      ingredients: []
    }
  end

  def create
    @recipe_form = RecipeForm.new(
      user: Current.user,
      title: recipe_params[:title],
      description: recipe_params[:description],
      tag_list: recipe_params[:tag_list],
      is_public: recipe_params[:is_public] == "true",
      ingredients_data: parse_ingredients_data
    )

    if @recipe_form.save
      redirect_to recipe_path(@recipe_form.recipe), notice: "Rezept wurde erfolgreich erstellt."
    else
      @errors = @recipe_form.errors.full_messages
      @recipe_form_data = {
        title: recipe_params[:title],
        description: recipe_params[:description],
        tagList: recipe_params[:tag_list],
        ingredients: format_ingredients_for_vue
      }
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb @recipe.title, recipe_path(@recipe)
    add_breadcrumb "Bearbeiten"

    @recipe_form_data = {
      title: @recipe.title,
      description: @recipe.description,
      tagList: @recipe.tag_list.join(", "),
      isPublic: @recipe.is_public,
      ingredients: @recipe.recipe_ingredients.map do |ri|
        {
          ingredientId: ri.ingredient_id,
          ingredientName: ri.ingredient.name,
          unitId: ri.unit_id,
          amount: ri.amount,
          additionalInfo: ri.additional_info,
          displayName: ri.display_name,
          isOptional: ri.is_optional,
          isScalable: ri.is_scalable
        }
      end
    }
  end

  def update
    @recipe_form = RecipeForm.new(
      recipe: @recipe,
      user: Current.user,
      title: recipe_params[:title],
      description: recipe_params[:description],
      tag_list: recipe_params[:tag_list],
      is_public: recipe_params[:is_public] == "true",
      ingredients_data: parse_ingredients_data
    )

    if @recipe_form.save
      redirect_to recipe_path(@recipe), notice: "Rezept wurde erfolgreich aktualisiert."
    else
      @errors = @recipe_form.errors.full_messages
      @recipe_form_data = {
        title: recipe_params[:title],
        description: recipe_params[:description],
        tagList: recipe_params[:tag_list],
        isPublic: recipe_params[:is_public] == "true",
        ingredients: format_ingredients_for_vue
      }
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.soft_delete!
    redirect_to recipes_path, notice: "Rezept wurde erfolgreich gelöscht."
  end

  def publish
    if @recipe.publish!
      redirect_to recipe_path(@recipe), notice: "Rezept wurde veröffentlicht."
    else
      redirect_to recipe_path(@recipe), alert: "Fehler beim Veröffentlichen."
    end
  end

  private

  def set_recipe
    @recipe = Recipe.unscoped.includes(
      :taggings,
      :tags,
      recipe_ingredients: [ :ingredient, :unit ],
      approved_recipe_images: [ :user, { image_attachment: :blob } ]
    ).find_by!(slug: params[:slug])
  end

  def authorize_view!
    unless can_view_recipe?(@recipe)
      redirect_to recipes_path, alert: "Rezept nicht gefunden oder keine Berechtigung."
    end
  end

  def authorize_edit!
    unless can_edit_recipe?(@recipe)
      redirect_to recipe_path(@recipe), alert: "Keine Berechtigung zum Bearbeiten."
    end
  end

  def authorize_delete!
    unless can_delete_recipe?(@recipe)
      redirect_to recipe_path(@recipe), alert: "Keine Berechtigung zum Löschen."
    end
  end

  def recipe_params
    params.require(:recipe).permit(:title, :description, :tag_list, :is_public, :ingredients_json)
  end

  def parse_ingredients_data
    return [] unless params[:recipe][:ingredients_json].present?

    JSON.parse(params[:recipe][:ingredients_json]).map do |ingredient|
      {
        ingredient_id: ingredient["ingredientId"],
        ingredient_name: ingredient["ingredientName"],
        unit_id: ingredient["unitId"],
        amount: ingredient["amount"],
        additional_info: ingredient["additionalInfo"],
        display_name: ingredient["displayName"],
        is_optional: ingredient["isOptional"],
        is_scalable: ingredient["isScalable"]
      }
    end
  rescue JSON::ParserError
    []
  end

  # Format ingredients data for Vue component (camelCase keys)
  def format_ingredients_for_vue
    return [] unless params[:recipe][:ingredients_json].present?

    JSON.parse(params[:recipe][:ingredients_json])
  rescue JSON::ParserError
    []
  end

  def sort_column
    %w[title average_rating alcohol_content visits_count users.username].include?(params[:sort]) ? params[:sort] : "visits_count"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
