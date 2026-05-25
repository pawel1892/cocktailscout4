class AddFulltextIndexToWikiArticles < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE wiki_articles ADD FULLTEXT INDEX index_wiki_articles_fulltext (title, body)"
  end

  def down
    execute "ALTER TABLE wiki_articles DROP INDEX index_wiki_articles_fulltext"
  end
end
