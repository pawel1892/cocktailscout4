class IngredientsController < ApplicationController
  load_and_authorize_resource :find_by => :slug
  before_action :find_ingredient, only: [:show, :edit, :update, :destroy]

  def index
    @ingredients = Ingredient.all.includes(recipe_ingredients: :recipe).order(:name).page(params[:page]).per(50)
  end

  def show
  end

  def new
    @ingredient = Ingredient.new
  end

  def edit
  end

  def create
    @ingredient = Ingredient.new(ingredient_params)

    if @ingredient.save
      redirect_to ingredients_path
    else
      render action: 'new'
    end
  end

  def update
    if @ingredient.update_attributes(ingredient_params)
      redirect_to ingredients_path
    else
      render action: 'edit'
    end
  end

  def destroy
    if @ingredient.recipes.present?
      redirect_to ingredients_path, alert: 'Zutat konnte nicht gelöscht werden, da sie noch in mindestens einem Rezept verwendet wird.'
      return
    end

    @ingredient.destroy
    redirect_to ingredients_path
  end

  protected

  def find_ingredient
    @ingredient = Ingredient.friendly.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name, :alcoholic_content)
  end
end
