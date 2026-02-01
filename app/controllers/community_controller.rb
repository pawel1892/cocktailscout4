class CommunityController < ApplicationController
  allow_unauthenticated_access

  def index
    add_breadcrumb "Community"
    @last_forum_threads = ForumThread.last_active_threads.limit(10)
    @last_recipe_comments = RecipeComment.order(created_at: :desc).limit(10)
    @online_users = User.online.order(last_active_at: :desc)
  end
end
