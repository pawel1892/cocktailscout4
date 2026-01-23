class RecipeCommentsController < ApplicationController
  include RecipeCommentsHelper
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :authorize_edit!, only: [ :edit, :update ]
  before_action :authorize_delete!, only: [ :destroy ]

  def create
    @recipe = Recipe.includes(
      :taggings,
      :tags,
      recipe_ingredients: :ingredient,
      approved_recipe_images: [ :user, { image_attachment: :blob } ]
    ).find_by!(slug: params[:id])

    # Ensure user is logged in for create (if not handled by router/view)
    unless Current.user
      flash[:alert] = "Du musst angemeldet sein."
      return redirect_to new_session_path
    end

    @comment = @recipe.recipe_comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to recipe_path(@recipe, anchor: "comment-#{@comment.id}"), notice: "Kommentar erfolgreich hinzugefügt."
    else
      # Re-load data needed for the show page
      @comments_pagy, @comments = pagy(
        @recipe.recipe_comments.includes(:user).order(created_at: :desc),
        limit: 30,
        page_key: "comments",
        url: recipe_path(@recipe)
      )
      flash.now[:alert] = "Kommentar konnte nicht gespeichert werden. Bitte korrigiere die Fehler."
      render "recipes/show", status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    @comment.last_editor = Current.user
    if @comment.update(comment_params)
      redirect_to recipe_path(@comment.recipe, anchor: "comment-#{@comment.id}"), notice: "Kommentar aktualisiert."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @comment.destroy
    redirect_to recipe_path(@comment.recipe, anchor: "comments"), notice: "Kommentar gelöscht."
  end

  private

  def set_comment
    @comment = RecipeComment.find(params[:id])
  end

  def comment_params
    params.require(:recipe_comment).permit(:body)
  end

  def authorize_edit!
    unless can_edit_comment?(@comment)
      redirect_to recipe_path(@comment.recipe), alert: "Keine Berechtigung."
    end
  end

  def authorize_delete!
    unless can_delete_comment?(@comment)
      redirect_to recipe_path(@comment.recipe), alert: "Keine Berechtigung."
    end
  end
end
