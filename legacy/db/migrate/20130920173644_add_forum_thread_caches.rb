class AddForumThreadCaches < ActiveRecord::Migration
  def change
    add_column :forum_threads, :post_count_cache, :integer
    add_column :forum_threads, :last_post_created_cache, :datetime
    add_column :forum_threads, :last_post_user_id_cache, :integer
  end
end
