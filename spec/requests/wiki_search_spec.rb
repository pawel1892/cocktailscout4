require "rails_helper"

RSpec.describe "Wiki Search", type: :request do
  let!(:gin_article) do
    create(:wiki_article,
      title: "Gin Guide",
      body: "Everything about juniper spirits and botanicals.",
      published: true)
  end

  let!(:rum_article) do
    create(:wiki_article,
      title: "Rum History",
      body: "Sugar cane distillates from the Caribbean.",
      published: true)
  end

  let!(:draft_article) do
    create(:wiki_article, :unpublished,
      title: "Gin Draft",
      body: "Unpublished gin content.")
  end

  describe "GET /wiki/search" do
    it "renders the search page without a query" do
      get search_wiki_articles_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Wiki-Suche")
    end

    it "is accessible without authentication" do
      get search_wiki_articles_path(q: "Gin")
      expect(response).to have_http_status(:success)
    end

    it "shows matching articles by title" do
      get search_wiki_articles_path(q: "Rum")
      expect(response.body).to include(wiki_article_path(rum_article))
      expect(response.body).not_to include(wiki_article_path(gin_article))
    end

    it "shows matching articles by body content" do
      get search_wiki_articles_path(q: "juniper")
      expect(response.body).to include(wiki_article_path(gin_article))
      expect(response.body).not_to include(wiki_article_path(rum_article))
    end

    it "does not show unpublished articles" do
      get search_wiki_articles_path(q: "Gin")
      expect(response.body).not_to include(wiki_article_path(draft_article))
    end

    it "shows a no-results message when nothing matches" do
      get search_wiki_articles_path(q: "xyznonexistent")
      expect(response.body).to include("Keine Artikel gefunden")
    end

    it "shows the result count when articles are found" do
      get search_wiki_articles_path(q: "Gin")
      expect(response.body).to include("gefunden")
    end

    it "echoes the query back in the search field" do
      get search_wiki_articles_path(q: "juniper")
      expect(response.body).to include('value="juniper"')
    end

    it "shows an empty-state prompt when no query is given" do
      get search_wiki_articles_path
      expect(response.body).to include("Gib einen Suchbegriff ein")
    end
  end
end
