class RecipeImagesController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @recipe_images = pagy(RecipeImage.approved.includes(:recipe, :user).order(created_at: :desc))
  end
end