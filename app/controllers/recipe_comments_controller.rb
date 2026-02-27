class RecipeCommentsController < ApplicationController
  include RecipeCommentsHelper
  allow_unauthenticated_access only: [ :index, :create ]
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :authorize_edit!, only: [ :edit, :update ]
  before_action :authorize_delete!, only: [ :destroy ]

  # GET /rezepte/:slug/comments — JSON endpoint for Vue component
  def index
    recipe = Recipe.find_by!(slug: params[:slug])
    comments = recipe.recipe_comments
      .top_level
      .includes(user: :user_stat, comment_votes: [], comment_type_taggings: [], comment_types: [],
                replies: [ { user: :user_stat }, :comment_votes ])
      .order(net_votes: :desc, created_at: :desc)

    render json: comments.map { |c| serialize_comment(c, include_replies: true) }
  end

  def create
    @recipe = Recipe.includes(
      :taggings,
      :tags,
      recipe_ingredients: :ingredient,
      approved_recipe_images: [ :user, { image_attachment: :blob } ]
    ).find_by!(slug: params[:slug])

    unless Current.user
      return respond_to do |format|
        format.json { render json: { error: "Du musst angemeldet sein." }, status: :unauthorized }
        format.html do
          flash[:alert] = "Du musst angemeldet sein."
          redirect_to new_session_path
        end
      end
    end

    @comment = @recipe.recipe_comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      respond_to do |format|
        format.json { render json: serialize_comment(@comment.reload, include_replies: true), status: :created }
        format.html { redirect_to recipe_path(@recipe, anchor: "comment-#{@comment.id}"), notice: "Kommentar erfolgreich hinzugefügt." }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_content }
        format.html do
          @comments_pagy, @comments = pagy(
            @recipe.recipe_comments.includes(:user).order(created_at: :desc),
            limit: 30,
            page_key: "comments",
            url: recipe_path(@recipe)
          )
          flash.now[:alert] = "Kommentar konnte nicht gespeichert werden."
          render "recipes/show", status: :unprocessable_content
        end
      end
    end
  end

  def edit
  end

  def update
    @comment.last_editor = Current.user
    if @comment.update(comment_params)
      respond_to do |format|
        format.json { render json: serialize_comment(@comment.reload, include_replies: false) }
        format.html { redirect_to recipe_path(@comment.recipe, anchor: "comment-#{@comment.id}"), notice: "Kommentar aktualisiert." }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_content }
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    recipe = @comment.recipe
    @comment.destroy
    respond_to do |format|
      format.json { render json: { success: true } }
      format.html { redirect_to recipe_path(recipe, anchor: "comments"), notice: "Kommentar gelöscht." }
    end
  end

  private

  def set_comment
    @comment = RecipeComment.find(params[:id])
  end

  def comment_params
    params.require(:recipe_comment).permit(:body, :parent_id)
  end

  def authorize_edit!
    unless can_edit_comment?(@comment)
      respond_to do |format|
        format.json { render json: { error: "Keine Berechtigung." }, status: :forbidden }
        format.html { redirect_to recipe_path(@comment.recipe), alert: "Keine Berechtigung." }
      end
    end
  end

  def authorize_delete!
    unless can_delete_comment?(@comment)
      respond_to do |format|
        format.json { render json: { error: "Keine Berechtigung." }, status: :forbidden }
        format.html { redirect_to recipe_path(@comment.recipe), alert: "Keine Berechtigung." }
      end
    end
  end

  def serialize_comment(comment, include_replies:)
    current_vote = Current.user ? comment.comment_votes.find { |v| v.user_id == Current.user.id } : nil
    {
      id: comment.id,
      body: comment.body,
      user: serialize_user(comment.user),
      created_at: comment.created_at.iso8601,
      updated_at: comment.updated_at.iso8601,
      last_editor_username: comment.last_editor&.username,
      net_votes: comment.net_votes,
      current_user_vote: current_vote&.value,
      tags: comment.comment_type_list,
      can_edit: can_edit_comment?(comment),
      can_delete: can_delete_comment?(comment),
      can_tag: Current.user&.can_moderate_recipe? || false,
      replies: include_replies ? comment.replies.sort_by(&:created_at).map { |r| serialize_comment(r, include_replies: false) } : []
    }
  end

  def serialize_user(user)
    return { id: nil, username: "Gelöschter Benutzer", rank: nil, online: false } unless user
    {
      id: user.id,
      username: user.username,
      rank: user.stat&.rank || 0,
      online: user.online?
    }
  end
end
