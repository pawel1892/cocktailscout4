class CreateIngredientWikiArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_wiki_articles do |t|
      t.bigint :ingredient_id,  null: false
      t.bigint :wiki_article_id, null: false
      t.timestamps
    end

    add_index :ingredient_wiki_articles, :ingredient_id
    add_index :ingredient_wiki_articles, :wiki_article_id
    add_index :ingredient_wiki_articles, [ :ingredient_id, :wiki_article_id ],
              unique: true, name: "index_ingredient_wiki_articles_unique"
    add_foreign_key :ingredient_wiki_articles, :ingredients
    add_foreign_key :ingredient_wiki_articles, :wiki_articles
  end
end
