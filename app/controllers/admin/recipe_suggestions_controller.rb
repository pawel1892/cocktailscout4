module Admin
  class RecipeSuggestionsController < BaseController
    before_action :require_recipe_moderator!
    before_action :set_suggestion, only: [ :show, :approve, :reject ]

    # GET /admin/recipe_suggestions
    def index
      @suggestions = RecipeSuggestion.includes(:user, :reviewed_by, :published_recipe)
                                     .then { |query| filter_by_status(query) }
                                     .recent

      @pagy, @suggestions = pagy(@suggestions, limit: 50)
    end

    # GET /admin/recipe_suggestions/:id
    def show
      @ingredients = @suggestion.recipe_suggestion_ingredients.includes(:ingredient, :unit)
    end

    # POST /admin/recipe_suggestions/:id/approve
    def approve
      ActiveRecord::Base.transaction do
        # 1. Create recipe from suggestion
        recipe_form = RecipeForm.new(
          user: @suggestion.user,  # Keep original author
          **@suggestion.to_recipe_params
        )

        unless recipe_form.save
          redirect_to admin_recipe_suggestion_path(@suggestion),
                      alert: "Fehler beim Erstellen des Rezepts: #{recipe_form.errors.full_messages.join(', ')}"
          return
        end

        # 2. Update suggestion
        @suggestion.update!(
          status: "approved",
          reviewed_by: Current.user,
          reviewed_at: Time.current,
          published_recipe: recipe_form.recipe
        )

        redirect_to admin_recipe_suggestions_path,
                    notice: "Vorschlag wurde genehmigt und als Rezept veröffentlicht."
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_recipe_suggestion_path(@suggestion),
                  alert: "Fehler: #{e.message}"
    end

    # POST /admin/recipe_suggestions/:id/reject
    def reject
      if @suggestion.update(
        status: "rejected",
        reviewed_by: Current.user,
        reviewed_at: Time.current,
        feedback: params[:feedback]
      )
        redirect_to admin_recipe_suggestions_path,
                    notice: "Vorschlag wurde abgelehnt."
      else
        redirect_to admin_recipe_suggestion_path(@suggestion),
                    alert: "Fehler beim Ablehnen des Vorschlags."
      end
    end

    # GET /admin/recipe_suggestions/count
    def count
      render json: {
        count: RecipeSuggestion.pending_review.count
      }
    end

    private

    def require_recipe_moderator!
      unless Current.user&.can_moderate_recipe?
        redirect_to root_path, alert: "Sie haben keine Berechtigung für diesen Bereich."
      end
    end

    def set_suggestion
      @suggestion = RecipeSuggestion.includes(:user, :recipe_suggestion_ingredients)
                                    .find(params[:id])
    end

    def filter_by_status(query)
      case params[:status]
      when "pending"
        query.status_pending
      when "approved"
        query.status_approved
      when "rejected"
        query.status_rejected
      else
        query  # all
      end
    end
  end
end
