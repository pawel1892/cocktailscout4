class AddBodyBbcodeToForumPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :forum_posts, :body_bbcode, :text
  end
end
