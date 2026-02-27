class CommentTagsController < ApplicationController
  allow_unauthenticated_access only: [ :create, :destroy ]
  before_action :require_moderator!
  before_action :set_comment

  ALLOWED_TAGS = %w[Markenempfehlung Zubereitungstipp Zutatenvariante Erfahrungsbericht].freeze

  def create
    tag = params[:tag].to_s.strip
    unless ALLOWED_TAGS.include?(tag)
      return render json: { error: "Unbekannter Tag." }, status: :unprocessable_content
    end

    tags = (@comment.comment_type_list + [ tag ]).uniq
    @comment.comment_type_list = tags
    @comment.save!

    render json: { tags: @comment.comment_type_list }
  end

  def destroy
    tag = params[:tag].to_s.strip
    tags = @comment.comment_type_list - [ tag ]
    @comment.comment_type_list = tags
    @comment.save!

    render json: { tags: @comment.comment_type_list }
  end

  private

  def set_comment
    @comment = RecipeComment.find(params[:id])
  end

  def require_moderator!
    unless Current.user&.can_moderate_recipe?
      render json: { error: "Keine Berechtigung." }, status: :forbidden
    end
  end
end
