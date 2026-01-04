class AddCacheToForumTopics < ActiveRecord::Migration
  def change
    add_column :forum_topics, :post_count_cache, :integer
    add_column :forum_topics, :thread_count_cache, :integer
    add_column :forum_topics, :last_post_id_cache, :integer
  end
end
