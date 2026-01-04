class ForumPostsController < ApplicationController
  load_and_authorize_resource

  def new
    @forum_thread = ForumThread.friendly.find(params[:thread_id])
    @forum_post = ForumPost.new
    if params[:quote].present?
      quoted_post = ForumPost.find(params[:quote])
      @quote = "[QUOTE #{quoted_post.user&.login}]#{quoted_post.content.gsub("<br />", "\n")}[/QUOTE]\n"
    end
    @last_forum_posts = @forum_thread.forum_posts.order('created_at DESC').limit(5)
  end

  def create

    @forum_thread = ForumThread.friendly.find(params[:thread_id])
    @forum_post = ForumPost.new
    @last_forum_posts = @forum_thread.forum_posts.order('created_at DESC').limit(5)

    @forum_thread = ForumThread.friendly.find(params[:thread_id])
    @forum_post = ForumPost.new(forum_post_params)
    @forum_post.content = ActionView::Base.full_sanitizer.sanitize(@forum_post.content).gsub("\n", "<br />")
    @forum_post.user = current_user
    @forum_post.forum_thread = @forum_thread
    if @forum_post.valid?
      @forum_post.save
      redirect_to forum_thread_path(@forum_post.forum_thread, params: { page: @forum_post.page }, anchor: @forum_post.id)
    else
      render :new
    end
  end

  def edit
    @forum_post = ForumPost.find(params[:id])
    @forum_post.content.gsub!("<br />", "\n")
  end

  def update
    @forum_post = ForumPost.find(params[:id])
    if @forum_post.update(forum_post_params.merge(last_editor_id: current_user.id))
      @forum_post.update_attribute(:content, ActionView::Base.full_sanitizer.sanitize(@forum_post.content).gsub("\n", "<br />"))
      redirect_to forum_thread_path(@forum_post.forum_thread, params: { page: @forum_post.page }, anchor: @forum_post.id)
    else
      render :edit
    end
  end

  def destroy
    @forum_post = ForumPost.find(params[:id])
    forum_thread = @forum_post.forum_thread
    forum_topic = forum_thread.forum_topic
    @forum_post.destroy
    if forum_thread.reload.present?
      redirect_to forum_thread_path(@forum_post.forum_thread.slug)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to forum_topic_path(forum_topic)
  end

  def report
    @forum_post = ForumPost.find(params[:id])
    #TODO link to exact post
    if PrivateMessage.report_to_forum_mods current_user, forum_thread_url(@forum_post.forum_thread)
      flash[:success] = 'Der Beitrag wurde gemeldet und die Moderatoren wurden benachrichtigt.'
      redirect_to forum_thread_path(@forum_post.forum_thread)
    end
  end

  private

  def forum_post_params
    params.require(:forum_post).permit(:content)
  end

end
