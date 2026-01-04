class RecipeCommentsController < ApplicationController
  load_and_authorize_resource

  def new
  end

  def index
    @recipe = Recipe.find_by_slug(params[:recipe_id])
    @recipe_comments = @recipe.recipe_comments.order("created_at DESC").page(params[:page]).per(APP_CONFIG[:recipe_comments][:per_page])
  end

  def create
    @recipe = Recipe.find_by_slug(params[:recipe_id])
    @recipe_comment = RecipeComment.new(recipe_comment_params)
    @recipe_comment.user_id = current_user.id
    @recipe_comment.recipe_id = @recipe.id
    @recipe_comment.comment = ActionView::Base.full_sanitizer.sanitize(params[:recipe_comment][:comment]).gsub("\n", "<br />")
    @recipe_comment.ip = request.remote_ip

    if @recipe_comment.save
      flash[:success] = 'Danke! Dein Kommentar wurde gespeichert.'
      redirect_to recipe_path(@recipe)
    else
      render action: "new"
    end
  end

  def edit
  end

  def recipe_comment_params
    params.require(:recipe_comment).permit(:comment)
  end
end
