module Admin
  class UnitsController < BaseController
    before_action :require_recipe_moderator!
    before_action :set_unit, only: [ :edit, :update, :destroy ]

    def index
      # Use LEFT JOIN to get recipe_ingredients count in single query
      @units = Unit.left_joins(:recipe_ingredients)
        .select("units.*, COUNT(DISTINCT recipe_ingredients.id) as usage_count")
        .group("units.id")
        .then { |query| apply_filters(query) }
        .then { |query| apply_sort(query) }

      @pagy, @units = pagy(@units, limit: 50)
    end

    def new
      @unit = Unit.new
    end

    def create
      @unit = Unit.new(unit_params)
      if @unit.save
        redirect_to admin_units_path, notice: "Einheit wurde erfolgreich erstellt."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @unit.update(unit_params)
        redirect_to admin_units_path, notice: "Einheit wurde erfolgreich aktualisiert."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      # Controller-level safety check
      if @unit.can_delete?
        @unit.destroy
        redirect_to admin_units_path, notice: "Einheit wurde erfolgreich gelöscht."
      else
        redirect_to admin_units_path,
          alert: "Einheit kann nicht gelöscht werden, da sie in #{@unit.recipe_ingredients_count} Rezeptzutat(en) verwendet wird."
      end
    end

    private

    def require_recipe_moderator!
      unless Current.user&.can_moderate_recipe?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end

    def set_unit
      @unit = Unit.find(params[:id])
    end

    def unit_params
      params.require(:unit).permit(:name, :display_name, :plural_name, :category, :ml_ratio, :divisible)
    end

    def apply_filters(query)
      query = filter_by_usage(query)
      query = filter_by_category(query)
      query = search_by_name(query) if params[:q].present?
      query
    end

    def filter_by_usage(query)
      case params[:usage]
      when "unused"
        query.having("COUNT(DISTINCT recipe_ingredients.id) = 0")
      when "used"
        query.having("COUNT(DISTINCT recipe_ingredients.id) > 0")
      else
        query
      end
    end

    def filter_by_category(query)
      case params[:category]
      when "volume", "count", "special"
        query.where(category: params[:category])
      else
        query
      end
    end

    def search_by_name(query)
      query.where("units.name LIKE ? OR units.display_name LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    def apply_sort(query)
      column = sort_column
      direction = sort_direction

      # For usage_count, we need to order by the aggregated column
      if column == "usage_count"
        sql_direction = direction == "desc" ? "DESC" : "ASC"
        query.order(Arel.sql("COUNT(DISTINCT recipe_ingredients.id) #{sql_direction}"))
      else
        query.order(column => direction)
      end
    end

    def sort_column
      %w[name display_name category usage_count created_at].include?(params[:sort]) ? params[:sort] : "name"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  end
end
