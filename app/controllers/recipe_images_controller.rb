class RecipeImagesController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @pagy, @recipe_images = pagy(RecipeImage.approved.includes(:recipe, :user).order(created_at: :desc))
  end
end
