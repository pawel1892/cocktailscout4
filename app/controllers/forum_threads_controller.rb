class ForumThreadsController < ApplicationController
  allow_unauthenticated_access

  helper_method :current_user

  def index
    @forum_topic = ForumTopic.find_by!(slug: params[:id])
    @pagy, @forum_threads = pagy(@forum_topic.forum_threads.order(updated_at: :desc), limit: 20)
  end

  def show
    @forum_thread = ForumThread.find_by!(slug: params[:id])
    @forum_thread.track_visit(Current.user)
    @forum_topic = @forum_thread.forum_topic
    @pagy, @forum_posts = pagy(@forum_thread.ordered_posts, limit: 20)
  end

  private

  def current_user
    Current.user
  end
end
