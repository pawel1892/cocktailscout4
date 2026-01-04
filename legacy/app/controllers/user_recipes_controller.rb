class UserRecipesController < ApplicationController
  load_and_authorize_resource

  before_action :check_params, :set_recipe

  def toggle
    if @recipe.is_favorite?(current_user)
      result = current_user.remove_favorite_recipe @recipe.id
    else
      result = current_user.add_favorite_recipe @recipe.id
    end

    if result
      render :json => true
    else
      render :json => false
    end
  end

  private

    def check_params
      unless current_user.present? && params.has_key?(:recipe_id)
        render :json => false
        return false
      end
    end

    def set_recipe
      @recipe = Recipe.find(params[:recipe_id]) rescue @recipe = nil
      if @recipe == nil
        render :json => false
        return false
      end
    end

end