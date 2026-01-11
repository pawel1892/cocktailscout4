class ForumTopicsController < ApplicationController
  allow_unauthenticated_access

  helper_method :current_user

  def index
    @forum_topics = ForumTopic.order(:position)
    @unread_topics = ForumTopic.unread_by(Current.user) if Current.user.present?
  end

  private

  def current_user
    Current.user
  end
end
