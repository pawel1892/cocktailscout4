class RecipeCommentsController < ApplicationController
  def create
    @recipe = Recipe.includes(
      :taggings,
      :tags,
      recipe_ingredients: :ingredient,
      approved_recipe_images: [ :user, { image_attachment: :blob } ]
    ).find_by!(slug: params[:recipe_id])

    @comment = @recipe.recipe_comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to recipe_path(@recipe, anchor: "comment-#{@comment.id}"), notice: "Kommentar erfolgreich hinzugefügt."
    else
      # Re-load data needed for the show page
      @comments_pagy, @comments = pagy(
        @recipe.recipe_comments.includes(:user).order(created_at: :desc),
        limit: 30,
        page_key: "comments"
      )
      flash.now[:alert] = "Kommentar konnte nicht gespeichert werden. Bitte korrigiere die Fehler."
      render "recipes/show", status: :unprocessable_content
    end
  end

  private

  def comment_params
    params.require(:recipe_comment).permit(:body)
  end
end
