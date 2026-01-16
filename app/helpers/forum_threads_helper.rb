module ForumThreadsHelper
  def link_to_forum_thread(forum_thread)
    if Current.user && forum_thread.first_unread_post(Current.user)
      forum_post = forum_thread.first_unread_post(Current.user)
      link_to_forum_post(forum_post)
    else
      forum_thread_path(forum_thread.slug)
    end
  end

  def link_to_forum_post(forum_post)
    forum_thread_path(forum_post.forum_thread.slug, page: forum_post.page, anchor: "post-#{forum_post.id}")
  end
end
