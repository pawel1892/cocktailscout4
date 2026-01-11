class AddVisitsCountToForumThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :forum_threads, :visits_count, :integer, default: 0, null: false
  end
end
