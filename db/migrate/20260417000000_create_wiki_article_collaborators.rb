class CreateWikiArticleCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_article_collaborators do |t|
      t.bigint :wiki_article_id, null: false
      t.bigint :user_id,         null: false
      t.timestamps
    end

    add_index :wiki_article_collaborators, :wiki_article_id
    add_index :wiki_article_collaborators, :user_id
    add_index :wiki_article_collaborators, [ :wiki_article_id, :user_id ],
              unique: true, name: "index_wiki_article_collaborators_unique"
    add_foreign_key :wiki_article_collaborators, :wiki_articles
    add_foreign_key :wiki_article_collaborators, :users
  end
end
