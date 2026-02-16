class RecipeSuggestionsController < ApplicationController
  allow_unauthenticated_access only: []  # Must be logged in

  before_action :set_suggestion, only: [ :show, :edit, :update ]
  before_action :ensure_editable, only: [ :edit, :update ]

  # GET /rezeptvorschlaege
  def index
    add_breadcrumb "Meine Rezeptvorschläge"

    @suggestions = Current.user.recipe_suggestions
                          .includes(:reviewed_by, :published_recipe)
                          .recent

    @pagy, @suggestions = pagy(@suggestions, limit: 20)
  end

  # GET /rezeptvorschlaege/new
  def new
    add_breadcrumb "Meine Rezeptvorschläge", recipe_suggestions_path
    add_breadcrumb "Neuer Vorschlag"

    @recipe_suggestion_form_data = {
      title: "",
      description: "",
      tagList: "",
      ingredients: []
    }
  end

  # POST /rezeptvorschlaege
  def create
    @recipe_suggestion_form = RecipeSuggestionForm.new(
      user: Current.user,
      title: suggestion_params[:title],
      description: suggestion_params[:description],
      tag_list: suggestion_params[:tag_list],
      ingredients_data: parse_ingredients_data
    )

    if @recipe_suggestion_form.save
      redirect_to recipe_suggestions_path,
                  notice: "Vielen Dank! Dein Rezeptvorschlag wurde eingereicht und wird geprüft."
    else
      @errors = @recipe_suggestion_form.errors.full_messages
      @recipe_suggestion_form_data = {
        title: suggestion_params[:title],
        description: suggestion_params[:description],
        tagList: suggestion_params[:tag_list],
        ingredients: format_ingredients_for_vue
      }
      render :new, status: :unprocessable_content
    end
  end

  # GET /rezeptvorschlaege/:id
  def show
    add_breadcrumb "Meine Rezeptvorschläge", recipe_suggestions_path
    add_breadcrumb @suggestion.title
  end

  # GET /rezeptvorschlaege/:id/edit
  def edit
    add_breadcrumb "Meine Rezeptvorschläge", recipe_suggestions_path
    add_breadcrumb @suggestion.title, recipe_suggestion_path(@suggestion)
    add_breadcrumb "Bearbeiten"

    @recipe_suggestion_form_data = {
      title: @suggestion.title,
      description: @suggestion.description,
      tagList: @suggestion.tag_list,
      ingredients: @suggestion.recipe_suggestion_ingredients.map do |rsi|
        {
          ingredientId: rsi.ingredient_id,
          ingredientName: rsi.ingredient.name,
          unitId: rsi.unit_id,
          amount: rsi.amount,
          additionalInfo: rsi.additional_info,
          displayName: rsi.display_name,
          isOptional: rsi.is_optional,
          isScalable: rsi.is_scalable
        }
      end
    }
  end

  # PATCH/PUT /rezeptvorschlaege/:id
  def update
    @recipe_suggestion_form = RecipeSuggestionForm.new(
      recipe_suggestion: @suggestion,
      user: Current.user,
      title: suggestion_params[:title],
      description: suggestion_params[:description],
      tag_list: suggestion_params[:tag_list],
      ingredients_data: parse_ingredients_data
    )

    if @recipe_suggestion_form.save
      redirect_to recipe_suggestions_path,
                  notice: "Dein Rezeptvorschlag wurde aktualisiert und erneut zur Prüfung eingereicht."
    else
      @errors = @recipe_suggestion_form.errors.full_messages
      @recipe_suggestion_form_data = {
        title: suggestion_params[:title],
        description: suggestion_params[:description],
        tagList: suggestion_params[:tag_list],
        ingredients: format_ingredients_for_vue
      }
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_suggestion
    @suggestion = Current.user.recipe_suggestions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to recipe_suggestions_path, alert: "Vorschlag nicht gefunden."
  end

  def ensure_editable
    unless @suggestion.editable_by?(Current.user)
      redirect_to recipe_suggestions_path,
                  alert: "Dieser Vorschlag kann nicht mehr bearbeitet werden."
    end
  end

  def suggestion_params
    params.require(:recipe_suggestion).permit(:title, :description, :tag_list, :ingredients_json)
  end

  def parse_ingredients_data
    return [] unless params[:recipe_suggestion][:ingredients_json].present?

    JSON.parse(params[:recipe_suggestion][:ingredients_json]).map do |ingredient|
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
    return [] unless params[:recipe_suggestion][:ingredients_json].present?

    JSON.parse(params[:recipe_suggestion][:ingredients_json])
  rescue JSON::ParserError
    []
  end
end
