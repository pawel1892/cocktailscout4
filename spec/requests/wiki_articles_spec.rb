require "rails_helper"

RSpec.describe "WikiArticles ingredient assignment", type: :request do
  let(:editor) { create(:user, :admin) }
  let!(:rum)   { create(:ingredient, name: "Rum") }
  let!(:gin)   { create(:ingredient, name: "Gin") }

  before { sign_in(editor) }

  describe "POST /wiki (create)" do
    it "assigns ingredients to the new article" do
      post wiki_articles_path, params: {
        wiki_article: {
          title: "Spirits Guide",
          body:  "About spirits.",
          ingredient_ids: [ rum.id.to_s, gin.id.to_s ]
        }
      }

      article = WikiArticle.find_by!(slug: "spirits-guide")
      expect(rum.reload.wiki_article).to eq(article)
      expect(gin.reload.wiki_article).to eq(article)
    end

    it "ignores blank ingredient_ids entries" do
      post wiki_articles_path, params: {
        wiki_article: {
          title: "Clean Slate",
          body:  "No ingredients.",
          ingredient_ids: [ "", "" ]
        }
      }

      article = WikiArticle.find_by!(slug: "clean-slate")
      expect(article.ingredients).to be_empty
    end
  end

  describe "PATCH /wiki/:slug (update)" do
    let!(:article) { create(:wiki_article, user: editor) }

    before do
      rum.update!(wiki_article: article)
      gin.update!(wiki_article: article)
    end

    it "adds new ingredients to the article" do
      vodka = create(:ingredient, name: "Vodka")

      patch wiki_article_path(article), params: {
        wiki_article: {
          title: article.title,
          body:  article.body,
          ingredient_ids: [ rum.id.to_s, vodka.id.to_s ]
        }
      }

      expect(vodka.reload.wiki_article).to eq(article)
    end

    it "nullifies wiki_article_id for removed ingredients" do
      patch wiki_article_path(article), params: {
        wiki_article: {
          title: article.title,
          body:  article.body,
          ingredient_ids: [ rum.id.to_s ]
        }
      }

      expect(gin.reload.wiki_article_id).to be_nil
      expect(rum.reload.wiki_article).to eq(article)
    end

    it "clears all ingredients when none are submitted" do
      patch wiki_article_path(article), params: {
        wiki_article: {
          title: article.title,
          body:  article.body,
          ingredient_ids: [ "" ]
        }
      }

      expect(rum.reload.wiki_article_id).to be_nil
      expect(gin.reload.wiki_article_id).to be_nil
    end

    it "moves an ingredient from another article to this one" do
      other_article = create(:wiki_article, user: editor)
      rum.update!(wiki_article: other_article)

      patch wiki_article_path(article), params: {
        wiki_article: {
          title: article.title,
          body:  article.body,
          ingredient_ids: [ rum.id.to_s ]
        }
      }

      expect(rum.reload.wiki_article).to eq(article)
    end
  end
end
