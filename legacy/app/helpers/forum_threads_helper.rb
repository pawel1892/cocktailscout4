module ForumThreadsHelper

  def link_to_forum_thread(forum_thread)
    if current_user && forum_thread.first_unread_post(current_user)
      forum_post = forum_thread.first_unread_post(current_user)
      link_to_forum_post(forum_post)
    else
      url_for forum_thread_path(forum_thread)
    end
  end

  def link_to_forum_post(forum_post)
    url_for forum_thread_path(forum_post.forum_thread, params: { page: forum_post.page }, anchor: forum_post.id)
  end

end
