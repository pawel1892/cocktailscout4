class CreateForumTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_topics do |t|
      t.string :name
      t.text :description
      t.string :slug
      t.integer :position
      t.integer :old_id

      t.timestamps
    end
    add_index :forum_topics, :slug
    add_index :forum_topics, :old_id
  end
end
