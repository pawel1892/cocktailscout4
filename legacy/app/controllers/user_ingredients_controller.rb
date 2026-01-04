class UserIngredientsController < ApplicationController
  load_and_authorize_resource

  before_action :check_params, :set_ingredient

  def toggle
    if @ingredient.is_in_mybar?(current_user)
      result = current_user.remove_mybar_ingredient @ingredient.id
    else
      result = current_user.add_mybar_ingredient @ingredient.id
    end

    if result
      render :json => true
    else
      render :json => false
    end
  end

  private

  def check_params
    unless current_user.present? && params.has_key?(:ingredient_id)
      render :json => false
      return false
    end
  end

  def set_ingredient
    @ingredient = Ingredient.find(params[:ingredient_id]) rescue @ingredient = nil
    if @ingredient == nil
      render :json => false
      return false
    end
  end

end