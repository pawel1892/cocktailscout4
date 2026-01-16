class AddFulltextIndexesToRecipesAndForum < ActiveRecord::Migration[8.1]
  def change
    add_index :recipes, :title, type: :fulltext
    add_index :forum_threads, :title, type: :fulltext
    add_index :forum_posts, :body, type: :fulltext
  end
end
