class IngredientSearchController < ApplicationController
  skip_authorization_check

  def index
    @ingredients = Ingredient.all
    @selected = session[:ingredient_search_selected_ingredients] ||= []
    @saved_ingredients = current_user&.user_ingredients
  end

  def create
    ingredients = params[:ingredients] ||= []
    session[:ingredient_search_selected_ingredients] = ingredients
    session[:ingredient_search_result_recipes] = (Recipe.mixable_from_ingredients ingredients).map(&:id)

    if params.has_key? :save
      current_user.save_mybar ingredients
    end

    redirect_to recipes_path(:ingredient_search => '1')
  end

  def load
    ingredients = current_user.user_ingredients.pluck(:ingredient_id).map(&:to_s)
    session[:ingredient_search_selected_ingredients] = ingredients

    redirect_to ingredient_search_path
  end

end
