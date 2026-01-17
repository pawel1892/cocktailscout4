class IngredientsController < ApplicationController
  def index
    if params[:q].present?
      @ingredients = Ingredient.where("name LIKE ?", "%#{params[:q]}%").limit(20)
    else
      @ingredients = Ingredient.limit(20)
    end

    respond_to do |format|
      format.json { render json: { ingredients: @ingredients.as_json(only: [ :id, :name ]) } }
    end
  end
end
