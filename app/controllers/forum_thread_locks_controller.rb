class ForumThreadLocksController < ApplicationController
  before_action :require_forum_moderator!

  def create
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])

    if @forum_thread.update(locked: true)
      redirect_to forum_thread_path(@forum_thread), notice: "Thread wurde gesperrt."
    else
      redirect_to forum_thread_path(@forum_thread), alert: "Fehler beim Sperren des Threads."
    end
  end

  def destroy
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])

    if @forum_thread.update(locked: false)
      redirect_to forum_thread_path(@forum_thread), notice: "Thread wurde entsperrt."
    else
      redirect_to forum_thread_path(@forum_thread), alert: "Fehler beim Entsperren des Threads."
    end
  end
end
