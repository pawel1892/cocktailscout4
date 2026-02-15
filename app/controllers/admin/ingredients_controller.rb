module Admin
  class IngredientsController < BaseController
    before_action :require_recipe_moderator!
    before_action :set_ingredient, only: [ :edit, :update, :destroy ]

    def index
      # Use LEFT JOIN to get recipe count in single query
      @ingredients = Ingredient.left_joins(:recipe_ingredients)
        .select("ingredients.*, COUNT(DISTINCT recipe_ingredients.recipe_id) as recipes_count")
        .group("ingredients.id")
        .then { |query| apply_filters(query) }
        .then { |query| apply_sort(query) }

      @pagy, @ingredients = pagy(@ingredients, limit: 50)
    end

    def new
      @ingredient = Ingredient.new
    end

    def create
      @ingredient = Ingredient.new(ingredient_params)
      if @ingredient.save
        redirect_to admin_ingredients_path, notice: "Zutat wurde erfolgreich erstellt."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @ingredient.update(ingredient_params)
        redirect_to admin_ingredients_path, notice: "Zutat wurde erfolgreich aktualisiert."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      # Controller-level safety check
      if @ingredient.can_delete?
        @ingredient.destroy
        redirect_to admin_ingredients_path, notice: "Zutat wurde erfolgreich gelöscht."
      else
        redirect_to admin_ingredients_path,
          alert: "Zutat kann nicht gelöscht werden, da sie in #{@ingredient.recipes_count} Rezept(en) verwendet wird."
      end
    end

    private

    def require_recipe_moderator!
      unless Current.user&.can_moderate_recipe?
        redirect_to root_path, alert: "Sie haben keine Berechtigung für diesen Bereich."
      end
    end

    def set_ingredient
      @ingredient = Ingredient.find(params[:id])
    end

    def ingredient_params
      params.require(:ingredient).permit(:name, :plural_name, :description, :alcoholic_content, :ml_per_unit)
    end

    def apply_filters(query)
      query = filter_by_usage(query)
      query = filter_by_alcohol(query)
      query = search_by_name(query) if params[:q].present?
      query
    end

    def filter_by_usage(query)
      case params[:usage]
      when "unused"
        query.having("COUNT(DISTINCT recipe_ingredients.recipe_id) = 0")
      when "used"
        query.having("COUNT(DISTINCT recipe_ingredients.recipe_id) > 0")
      else
        query
      end
    end

    def filter_by_alcohol(query)
      case params[:alcohol]
      when "alcoholic"
        query.where("alcoholic_content > 0")
      when "non_alcoholic"
        query.where("alcoholic_content = 0")
      else
        query
      end
    end

    def search_by_name(query)
      query.where("ingredients.name LIKE ?", "%#{params[:q]}%")
    end

    def apply_sort(query)
      column = sort_column
      direction = sort_direction

      # For recipes_count, we need to order by the aggregated column
      if column == "recipes_count"
        # Use explicit ASC/DESC to avoid SQL injection warning
        sql_direction = direction == "desc" ? "DESC" : "ASC"
        query.order(Arel.sql("COUNT(DISTINCT recipe_ingredients.recipe_id) #{sql_direction}"))
      else
        query.order(column => direction)
      end
    end

    def sort_column
      %w[name recipes_count alcoholic_content created_at].include?(params[:sort]) ? params[:sort] : "name"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  end
end
