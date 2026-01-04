class AddSortingToForumTopics < ActiveRecord::Migration
  def change
    add_column :forum_topics, :sorting, :integer
  end
end
