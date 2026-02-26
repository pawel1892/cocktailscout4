class RecipeImagesController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def new
    @recipe = Recipe.find_by!(slug: params[:slug])
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb @recipe.title, recipe_path(@recipe)
    add_breadcrumb "Bild hochladen"
  end

  def index
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb "Cocktailgalerie"
    query = RecipeImage.approved.not_soft_deleted.includes(:recipe, :user, image_attachment: :blob).order(created_at: :desc)
    query = query.by_user(params[:user_id])
    query = query.by_recipe_name(params[:q])
    @filter_user = User.find_by(id: params[:user_id]) if params[:user_id].present?
    @pagy, @recipe_images = pagy(query, limit: 60)
  end

  def create
    @recipe = Recipe.find_by!(slug: params[:slug])

    @recipe_image = @recipe.recipe_images.build(user: Current.user)
    @recipe_image.image.attach(params[:image])

    if @recipe_image.save
      render json: {
        success: true,
        message: "Bild hochgeladen. Es wird nach Überprüfung freigegeben."
      }
    else
      render json: {
        success: false,
        errors: @recipe_image.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
