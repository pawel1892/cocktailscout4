module Admin
  class RecipesController < BaseController
    before_action :require_recipe_moderator!

    def index
      @recipes = Recipe.unscoped  # Include deleted recipes
                       .includes(:user, :recipe_ingredients)
                       .then { |query| apply_filters(query) }
                       .order(sort_column => sort_direction)

      @pagy, @recipes = pagy(@recipes, limit: 50)
    end

    private

    def require_recipe_moderator!
      unless Current.user&.can_moderate_recipe?
        redirect_to root_path, alert: "Sie haben keine Berechtigung für diesen Bereich."
      end
    end

    def apply_filters(query)
      query = filter_by_status(query)
      query = filter_by_needs_attention(query)
      query = search_by_title(query) if params[:q].present?
      query
    end

    def filter_by_status(query)
      case params[:status]
      when "draft"
        query.where(is_public: false, is_deleted: false)
      when "published"
        query.where(is_public: true, is_deleted: false)
      when "deleted"
        query.where(is_deleted: true)
      else
        query  # all
      end
    end

    def filter_by_needs_attention(query)
      return query unless params[:needs_attention] == "true"

      # Use scope to find recipes with ingredients that need review
      query.needs_unit_migration_attention
    end

    def search_by_title(query)
      query.where("recipes.title LIKE ?", "%#{params[:q]}%")
    end

    def sort_column
      %w[title visits_count average_rating alcohol_content created_at updated_at].include?(params[:sort]) ? params[:sort] : "visits_count"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
  end
end
