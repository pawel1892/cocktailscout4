class RecipesController < ApplicationController
  include RecipesHelper
  include RecipeCommentsHelper
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_recipe, only: %i[ show ]
  before_action :authorize_view!, only: %i[ show ]
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
    query = query.by_user(params[:user_id])

    # Filter by favorites
    if params[:filter] == "favorites" && authenticated?
      query = query.joins(:favorites).where(favorites: { user_id: Current.user.id })
    end

    # Filter data
    @tags = ActsAsTaggableOn::Tag.order(:name)
    @ingredients = Ingredient.order(:name)
    @collections = authenticated? ? Current.user.ingredient_collections.order(is_default: :desc, name: :asc) : []
    @filter_user = User.find_by(id: params[:user_id]) if params[:user_id].present?
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

    @comments_json = build_comments_json(@recipe)

    @recipe.track_visit(Current.user)
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

  def build_comments_json(recipe)
    comments = recipe.recipe_comments
      .top_level
      .includes(user: :user_stat, comment_votes: [], comment_type_taggings: [], comment_types: [],
                replies: [ { user: :user_stat }, :comment_votes ])
      .order(net_votes: :desc, created_at: :desc)

    comments.map { |c| serialize_comment_for_json(c) }.to_json
  end

  def serialize_comment_for_json(comment)
    current_vote = Current.user ? comment.comment_votes.find { |v| v.user_id == Current.user.id } : nil
    {
      id: comment.id,
      body: comment.body,
      user: comment.user ? { id: comment.user.id, username: comment.user.username, rank: comment.user.stat&.rank || 0, online: comment.user.online? } : { id: nil, username: "Gelöschter Benutzer", rank: nil, online: false },
      created_at: comment.created_at.iso8601,
      updated_at: comment.updated_at.iso8601,
      last_editor_username: comment.last_editor&.username,
      net_votes: comment.net_votes,
      current_user_vote: current_vote&.value,
      tags: comment.comment_type_list,
      can_edit: can_edit_comment?(comment),
      can_delete: can_delete_comment?(comment),
      can_tag: Current.user&.can_moderate_recipe? || false,
      replies: comment.replies.sort_by(&:created_at).map { |r| serialize_comment_for_json(r) }
    }
  end

  def sort_column
    %w[title average_rating alcohol_content visits_count users.username].include?(params[:sort]) ? params[:sort] : "visits_count"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
