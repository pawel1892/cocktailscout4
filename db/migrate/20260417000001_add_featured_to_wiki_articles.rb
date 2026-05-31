class AddFeaturedToWikiArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :wiki_articles, :featured, :boolean, default: false, null: false
    add_column :wiki_articles, :featured_position, :integer
    add_index :wiki_articles, :featured
  end
end
