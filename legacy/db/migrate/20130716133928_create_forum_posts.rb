class CreateForumPosts < ActiveRecord::Migration
  def change
    create_table :forum_posts do |t|
      t.integer :forum_thread_id
      t.integer :user_id
      t.string :ip
      t.text :content
      t.boolean :deleted
      t.integer :last_editor_id

      t.timestamps
    end
  end
end
