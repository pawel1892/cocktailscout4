class CreateForumTopics < ActiveRecord::Migration
  def change
    create_table :forum_topics do |t|
      t.string :name
      t.text :description
      t.string :slug

      t.timestamps
    end
  end
end
