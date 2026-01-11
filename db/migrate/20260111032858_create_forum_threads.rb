class CreateForumThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_threads do |t|
      t.references :forum_topic, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :title
      t.string :slug
      t.boolean :sticky, default: false, null: false
      t.boolean :locked, default: false, null: false
      t.boolean :deleted, default: false, null: false
      t.integer :old_id

      t.timestamps
    end
    add_index :forum_threads, :slug
    add_index :forum_threads, :old_id
  end
end
