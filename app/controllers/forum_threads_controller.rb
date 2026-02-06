class ForumThreadsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  helper_method :current_user

  def index
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum", forum_topics_path
    @forum_topic = ForumTopic.find_by!(slug: params[:id])
    @pagy, @forum_threads = pagy(@forum_topic.forum_threads.order(sticky: :desc, updated_at: :desc), limit: 20)
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
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_forum_topic
    ForumTopic.find_by(slug: params[:topic_id]) || ForumTopic.find(params[:topic_id])
  end

  def forum_thread_form_params
    params.require(:forum_thread_form).permit(:thread_title, :post_content)
  end

  def current_user
    Current.user
  end
end
