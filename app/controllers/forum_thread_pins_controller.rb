class ForumThreadPinsController < ApplicationController
  before_action :require_forum_moderator!

  def create
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])

    if @forum_thread.update(sticky: true)
      redirect_to forum_thread_path(@forum_thread), notice: "Thread wurde angepinnt."
    else
      redirect_to forum_thread_path(@forum_thread), alert: "Fehler beim Anpinnen des Threads."
    end
  end

  def destroy
    @forum_thread = ForumThread.find_by!(slug: params[:thread_id])

    if @forum_thread.update(sticky: false)
      redirect_to forum_thread_path(@forum_thread), notice: "Thread wurde losgelöst."
    else
      redirect_to forum_thread_path(@forum_thread), alert: "Fehler beim Loslösen des Threads."
    end
  end
end
