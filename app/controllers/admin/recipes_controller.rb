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

    def new
      @recipe_form_data = {
        title: "",
        description: "",
        tagList: "",
        isPublic: false,
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
        redirect_to admin_recipes_path, notice: "Rezept wurde erfolgreich erstellt."
      else
        @errors = @recipe_form.errors.full_messages
        @recipe_form_data = {
          title: recipe_params[:title],
          description: recipe_params[:description],
          tagList: recipe_params[:tag_list],
          isPublic: recipe_params[:is_public] == "true",
          ingredients: format_ingredients_for_vue
        }
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @recipe = Recipe.unscoped.find(params[:id])
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
            isScalable: ri.is_scalable,
            needsReview: ri.needs_review,
            oldDescription: ri.old_description
          }
        end
      }
    end

    def update
      @recipe = Recipe.unscoped.find(params[:id])
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
        redirect_to admin_recipes_path, notice: "Rezept wurde erfolgreich aktualisiert."
      else
        @errors = @recipe_form.errors.full_messages
        @recipe_form_data = {
          title: recipe_params[:title],
          description: recipe_params[:description],
          tagList: recipe_params[:tag_list],
          isPublic: recipe_params[:is_public] == "true",
          ingredients: format_ingredients_for_vue
        }
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @recipe = Recipe.unscoped.find(params[:id])
      @recipe.soft_delete!
      redirect_to admin_recipes_path, notice: "Rezept wurde gelöscht."
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
  end
end
