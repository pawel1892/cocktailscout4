class AddIndexes < ActiveRecord::Migration
  def change
    add_index :visits, :user_id
    add_index :visits, :visitable_id
    add_index :visits, :visitable_type
    add_index :visits, :last_visit_time
    add_index :forum_threads, :user_id
    add_index :forum_threads, :forum_topic_id
  end
end
