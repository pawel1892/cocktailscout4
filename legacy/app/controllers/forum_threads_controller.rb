class ForumThreadsController < ApplicationController
  load_and_authorize_resource :find_by => :slug

  def show
    @forum_thread = ForumThread.friendly.find(params[:id])
    Visit.track(@forum_thread, current_user)
    @forum_topic = @forum_thread.forum_topic
    @forum_posts = @forum_thread.ordered_posts_by_page(params[:page])
  end

  def new
    @forum_topic = ForumTopic.friendly.find(params[:topic_id])
    @forum_thread_form = ForumThreadForm.new
  end

  def create
    if params.has_key? :forum_thread_form
      form_params = params[:forum_thread_form]
      thread_title = form_params[:thread_title]
      post_content = ActionView::Base.full_sanitizer.sanitize(form_params[:post_content]).gsub("\n", "<br />")
    else
      thread_title = nil
      post_content = nil
    end
    @forum_topic = ForumTopic.friendly.find(params[:topic_id])
    @forum_thread_form = ForumThreadForm.new(
      user: current_user,
      forum_topic: @forum_topic,
      thread_title: thread_title,
      post_content: post_content
    )
    if @forum_thread_form.valid?
      forum_thread = @forum_thread_form.save
      redirect_to forum_thread_path(forum_thread.slug), :flash => { :success => "Dein Thread wurde erfolgreich erstellt." }
    else
      render :new
    end
  end

end
