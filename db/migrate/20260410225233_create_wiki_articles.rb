class CreateWikiArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_articles do |t|
      t.string   :title,          null: false
      t.string   :slug,           null: false
      t.longtext :body
      t.bigint   :user_id,        null: false
      t.bigint   :last_editor_id
      t.bigint   :ingredient_id
      t.boolean  :published,      null: false, default: false
      t.timestamps
    end

    add_index :wiki_articles, :slug,          unique: true
    add_index :wiki_articles, :ingredient_id, unique: true
    add_index :wiki_articles, :user_id
    add_index :wiki_articles, :published
  end
end
