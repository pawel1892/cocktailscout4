require "rails_helper"

RSpec.describe WikiArticle, type: :model do
  describe ".search" do
    let!(:gin_article)   { create(:wiki_article, title: "Gin Guide", body: "Everything about juniper spirits.") }
    let!(:rum_article)   { create(:wiki_article, title: "Rum History", body: "Sugar cane distillates explained.") }
    let!(:draft_article) { create(:wiki_article, :unpublished, title: "Gin Draft", body: "Unpublished gin content.") }

    it "returns articles matching by title" do
      results = WikiArticle.published.search("Rum")
      expect(results).to include(rum_article)
      expect(results).not_to include(gin_article)
    end

    it "returns articles matching by body" do
      results = WikiArticle.published.search("juniper")
      expect(results).to include(gin_article)
      expect(results).not_to include(rum_article)
    end

    it "returns none for blank query" do
      expect(WikiArticle.search("")).to eq(WikiArticle.none)
      expect(WikiArticle.search(nil)).to eq(WikiArticle.none)
    end

    it "is case-insensitive" do
      results = WikiArticle.published.search("rum")
      expect(results).to include(rum_article)
    end

    it "does not return unpublished articles when scoped to published" do
      results = WikiArticle.published.search("Gin")
      expect(results).not_to include(draft_article)
    end
  end
end
