class ForumTopicsController < ApplicationController
  allow_unauthenticated_access

  helper_method :current_user

  def index
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum"
    @forum_topics = ForumTopic.order(:position)
    @unread_topic_ids = ForumTopic.unread_by(Current.user).pluck("forum_topics.id") if Current.user.present?
  end

  private

  def current_user
    Current.user
  end
end
