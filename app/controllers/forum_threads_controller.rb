class ForumThreadsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  before_action :require_admin_for_news_forum!, only: %i[new create]

  helper_method :current_user

  def index
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum", forum_topics_path
    @forum_topic = ForumTopic.find_by!(slug: params[:id])
    @pagy, @forum_threads = pagy(
      @forum_topic.forum_threads
        .joins("LEFT JOIN forum_posts ON forum_posts.forum_thread_id = forum_threads.id AND forum_posts.deleted = false")
        .select("forum_threads.*, COALESCE(MAX(forum_posts.created_at), forum_threads.created_at) AS last_post_at")
        .group("forum_threads.id")
        .order(Arel.sql("forum_threads.sticky DESC, COALESCE(MAX(forum_posts.created_at), forum_threads.created_at) DESC")),
      limit: 20
    )
  end

  def show
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum", forum_topics_path
    @forum_thread = ForumThread.find_by!(slug: params[:id])
    @forum_thread.track_visit(Current.user)
    @forum_topic = @forum_thread.forum_topic
    @pagy, @forum_posts = pagy(@forum_thread.ordered_posts, limit: 20)
    set_forum_thread_meta_tags(@forum_thread)
  end

  def new
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum", forum_topics_path
    @forum_topic = find_forum_topic
    @forum_thread_form = ForumThreadForm.new
  end

  def create
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum", forum_topics_path
    @forum_topic = find_forum_topic

    @forum_thread_form = ForumThreadForm.new(forum_thread_form_params)
    @forum_thread_form.user = Current.user
    @forum_thread_form.forum_topic = @forum_topic

    if @forum_thread_form.save
      redirect_to forum_thread_path(@forum_thread_form.forum_thread), notice: "Thema erfolgreich erstellt."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def find_forum_topic
    ForumTopic.find_by(slug: params[:topic_id]) || ForumTopic.find(params[:topic_id])
  end

  def require_admin_for_news_forum!
    topic = find_forum_topic
    authorization_redirect if topic.news? && !Current.user&.admin?
  end

  def forum_thread_form_params
    params.require(:forum_thread_form).permit(:thread_title, :post_content)
  end

  def current_user
    Current.user
  end
end
