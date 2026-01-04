class CommunityController < ApplicationController
  skip_authorization_check

  add_breadcrumb "Community", :community_path

  def index
    @last_forum_threads = ForumThread.last_active_threads.limit(10)
    @last_recipe_comments = RecipeComment.order('created_at DESC').limit(10)
    @online_users = User.online.order('last_sign_in_at DESC')
  end

end