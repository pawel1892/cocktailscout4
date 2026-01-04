class ForumSearchController < ApplicationController
  skip_authorization_check

  def search
    @query = params[:forum_search_query]
    @forum_threads = ForumThread.where('title like ?', '%' + @query + '%').order('created_at DESC').limit(200)
    @forum_posts = ForumPost.where('content like ?', '%' + @query + '%').order('created_at DESC').limit(50)
  end

end
