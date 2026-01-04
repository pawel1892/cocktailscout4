class RecipeImagesController < ApplicationController
  load_and_authorize_resource

  def index
    to_approve = params[:to_approve]
    @recipe_images = RecipeImage.joins(:recipe).page(params[:page]).per(24)
    if to_approve && can?(:approve, RecipeImage)
      @recipe_images = @recipe_images.to_approve
    else
      @recipe_images = @recipe_images.approved.order('updated_at DESC')
    end
  end

  def new
    @recipe_image = RecipeImage.new
    @recipe = Recipe.find_by_slug!(params[:recipe_id])
  end

  def create
    @recipe_image = RecipeImage.new(recipe_image_params)
    @recipe = Recipe.find_by_slug(params[:recipe_id])
    @recipe_image.user_id = current_user.id
    @recipe_image.recipe_id = @recipe.id

    if @recipe_image.save
      redirect_to recipe_path(@recipe), notice: 'Danke! Dein Bild wurde hochgeladen.'
    else
      render action: "new"
    end
  end

  def approve
    @recipe_image = RecipeImage.find(params[:recipe_image_id])
    @recipe_image.approve!(current_user, params[:approve_state])
    redirect_to recipe_images_path(not_approved: true), notice: 'Das Bild wurde freigeschaltet.'
  end

  private

  def recipe_image_params
    params.require(:recipe_image).permit(:image)
  end
end
