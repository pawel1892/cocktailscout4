class ForumThreadMovesController < ApplicationController
  before_action :require_forum_moderator!

  def create
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])
    target_topic = ForumTopic.find(params[:forum_topic_id])

    if target_topic.news? && !Current.user.admin?
      redirect_to forum_thread_path(@forum_thread), alert: "Nur Administratoren können Threads ins News-Forum verschieben."
      return
    end

    if @forum_thread.update(forum_topic_id: target_topic.id)
      redirect_to forum_thread_path(@forum_thread), notice: "Thread wurde nach \"#{target_topic.name}\" verschoben."
    else
      redirect_to forum_thread_path(@forum_thread), alert: "Fehler beim Verschieben des Threads."
    end
  end
end
