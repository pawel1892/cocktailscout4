require "rails_helper"

RSpec.describe "WikiArticles ingredient assignment", type: :request do
  let(:editor) { create(:user, :wiki_editor) }
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

RSpec.describe "WikiArticles authorization", type: :request do
  let(:article) { create(:wiki_article, title: "Original Wiki Title", body: "Original body.") }
  let(:article_params) do
    {
      wiki_article: {
        title: "Changed Wiki Title",
        body: "Changed body."
      }
    }
  end

  shared_examples "cannot modify wiki articles" do
    it "cannot open the new article form" do
      get new_wiki_article_path

      expect(response).to redirect_to(root_path)
    end

    it "cannot create wiki articles" do
      expect do
        post wiki_articles_path, params: article_params
      end.not_to change(WikiArticle, :count)

      expect(response).to redirect_to(root_path)
    end

    it "cannot open the edit form" do
      get edit_wiki_article_path(article)

      expect(response).to redirect_to(root_path)
    end

    it "cannot update wiki articles" do
      patch wiki_article_path(article), params: article_params

      expect(response).to redirect_to(root_path)
      expect(article.reload.title).to eq("Original Wiki Title")
    end

    it "cannot delete wiki articles" do
      article

      expect do
        delete wiki_article_path(article)
      end.not_to change(WikiArticle, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  context "when authenticated as wiki editor" do
    before { sign_in(create(:user, :wiki_editor)) }

    it "can open the new article form" do
      get new_wiki_article_path

      expect(response).to have_http_status(:success)
    end

    it "can create wiki articles" do
      expect do
        post wiki_articles_path, params: article_params
      end.to change(WikiArticle, :count).by(1)
    end

    it "can open the edit form" do
      get edit_wiki_article_path(article)

      expect(response).to have_http_status(:success)
    end

    it "can update wiki articles" do
      patch wiki_article_path(article), params: article_params

      expect(response).to redirect_to(wiki_article_path(article.reload))
      expect(article.title).to eq("Changed Wiki Title")
    end

    it "can delete wiki articles" do
      article

      expect do
        delete wiki_article_path(article)
      end.to change(WikiArticle, :count).by(-1)
    end
  end

  context "when authenticated as admin without wiki_editor role" do
    before { sign_in(create(:user, :admin)) }

    include_examples "cannot modify wiki articles"
  end

  context "when authenticated as super moderator without wiki_editor role" do
    before { sign_in(create(:user, :super_moderator)) }

    include_examples "cannot modify wiki articles"
  end

  context "when authenticated as regular user" do
    before { sign_in(create(:user)) }

    include_examples "cannot modify wiki articles"
  end

  context "when unauthenticated" do
    it "redirects create to login" do
      expect do
        post wiki_articles_path, params: article_params
      end.not_to change(WikiArticle, :count)

      expect(response).to redirect_to(new_session_path)
    end

    it "redirects update to login" do
      patch wiki_article_path(article), params: article_params

      expect(response).to redirect_to(new_session_path)
      expect(article.reload.title).to eq("Original Wiki Title")
    end

    it "redirects delete to login" do
      article

      expect do
        delete wiki_article_path(article)
      end.not_to change(WikiArticle, :count)

      expect(response).to redirect_to(new_session_path)
    end
  end
end
