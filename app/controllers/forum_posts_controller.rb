class ForumPostsController < ApplicationController
  # Standard CRUD actions require auth

  before_action :set_forum_post, only: %i[edit update destroy]
  before_action :authorize_edit!, only: %i[edit update]
  before_action :authorize_delete!, only: %i[destroy]

  def new
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])
    @forum_post = @forum_thread.forum_posts.new

    if params[:quote].present?
      quoted_post = ForumPost.find_by(id: params[:quote])
      if quoted_post
        @forum_post.body = "[quote=#{quoted_post.user&.username || 'Gast'}]#{quoted_post.body}[/quote]\n"
      end
    end

    # Show last posts for context
    @last_forum_posts = @forum_thread.forum_posts.order(created_at: :desc).limit(5)
  end

  def create
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])
    @forum_post = @forum_thread.forum_posts.new(forum_post_params)
    @forum_post.user = Current.user

    if @forum_post.save
      # Calculate page of new post
      page = @forum_post.page
      redirect_to forum_thread_path(@forum_thread, page: page, anchor: "post-#{@forum_post.id}"), notice: "Beitrag erfolgreich erstellt."
    else
      @last_forum_posts = @forum_thread.forum_posts.order(created_at: :desc).limit(5)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    # @forum_post is set by before_action
  end

  def update
    if @forum_post.update(forum_post_params.merge(last_editor: Current.user))
      page = @forum_post.page
      redirect_to forum_thread_path(@forum_post.forum_thread, page: page, anchor: "post-#{@forum_post.id}"), notice: "Beitrag aktualisiert."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    forum_thread = @forum_post.forum_thread
    forum_topic = forum_thread.forum_topic

    # Soft delete
    @forum_post.update(deleted: true)

    # Check if thread is still visible (not deleted)
    if ForumThread.exists?(id: forum_thread.id)
      redirect_to forum_thread_path(forum_thread), notice: "Beitrag gelöscht."
    else
      redirect_to forum_topic_path(forum_topic), notice: "Das Thema wurde gelöscht, da es keine sichtbaren Beiträge mehr enthielt."
    end
  end

  private

  def set_forum_post
    @forum_post = ForumPost.find(params[:id])
  end

  def authorize_edit!
    unless @forum_post.user == Current.user || Current.user&.admin? || Current.user&.forum_moderator?
      redirect_to forum_thread_path(@forum_post.forum_thread), alert: "Du hast keine Berechtigung, diesen Beitrag zu bearbeiten."
    end
  end

  def authorize_delete!
    unless Current.user&.admin? || Current.user&.forum_moderator?
      redirect_to forum_thread_path(@forum_post.forum_thread), alert: "Du hast keine Berechtigung, diesen Beitrag zu löschen."
    end
  end

  def forum_post_params
    params.require(:forum_post).permit(:body)
  end
end
