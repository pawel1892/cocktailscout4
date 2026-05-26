class ReplaceIngredientWikiArticlesWithDirectFk < ActiveRecord::Migration[8.1]
  def up
    add_reference :ingredients, :wiki_article, foreign_key: true, null: true

    execute <<~SQL
      UPDATE ingredients i
      JOIN (
        SELECT ingredient_id, MIN(wiki_article_id) AS wiki_article_id
        FROM ingredient_wiki_articles
        GROUP BY ingredient_id
      ) iwa ON i.id = iwa.ingredient_id
      SET i.wiki_article_id = iwa.wiki_article_id
    SQL

    drop_table :ingredient_wiki_articles
  end

  def down
    create_table :ingredient_wiki_articles do |t|
      t.bigint :ingredient_id, null: false
      t.bigint :wiki_article_id, null: false
      t.timestamps
    end

    add_index :ingredient_wiki_articles, :ingredient_id
    add_index :ingredient_wiki_articles, :wiki_article_id
    add_index :ingredient_wiki_articles, [ :ingredient_id, :wiki_article_id ],
              unique: true, name: "index_ingredient_wiki_articles_unique"
    add_foreign_key :ingredient_wiki_articles, :ingredients
    add_foreign_key :ingredient_wiki_articles, :wiki_articles

    execute <<~SQL
      INSERT INTO ingredient_wiki_articles (ingredient_id, wiki_article_id, created_at, updated_at)
      SELECT id, wiki_article_id, NOW(), NOW()
      FROM ingredients
      WHERE wiki_article_id IS NOT NULL
    SQL

    remove_reference :ingredients, :wiki_article
  end
end
