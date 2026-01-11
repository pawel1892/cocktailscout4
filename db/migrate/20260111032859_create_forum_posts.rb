class CreateForumPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_posts do |t|
      t.references :forum_thread, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.text :body
      t.integer :old_id

      t.timestamps
    end
    add_index :forum_posts, :old_id
  end
end
