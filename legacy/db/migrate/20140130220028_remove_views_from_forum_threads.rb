class RemoveViewsFromForumThreads < ActiveRecord::Migration
  def change
    remove_column :forum_threads, :views, :integer
  end
end
