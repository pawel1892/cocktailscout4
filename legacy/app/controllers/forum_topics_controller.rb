class ForumTopicsController < ApplicationController
  load_and_authorize_resource :find_by => :slug

  def index
    @forum_topics = ForumTopic.order('sorting ASC')
    @unread_topics = ForumTopic.unread_by(current_user) if current_user.present?
  end

  def show
    @forum_topic = ForumTopic.friendly.find(params[:id])
    @forum_threads = @forum_topic.forum_threads.order('last_post_created_cache DESC').page(params[:page]).per(APP_CONFIG[:forum_threads][:per_page])
  end

end
