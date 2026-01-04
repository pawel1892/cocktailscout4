class Addindexes < ActiveRecord::Migration
  def change
    add_index :forum_threads, :last_post_created_cache
  end
end
