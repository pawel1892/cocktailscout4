class RecipeImagesController < ApplicationController

  def index
    @pagy, @recipe_images = pagy(RecipeImage.approved.includes(:recipe, :user).order(created_at: :desc))
  end
end