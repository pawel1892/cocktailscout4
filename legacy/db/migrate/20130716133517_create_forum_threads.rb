class CreateForumThreads < ActiveRecord::Migration
  def change
    create_table :forum_threads do |t|
      t.integer :forum_topic_id
      t.integer :user_id
      t.string :title
      t.integer :views
      t.boolean :sticky
      t.boolean :locked
      t.boolean :deleted
      t.string :slug

      t.timestamps
    end
  end
end
