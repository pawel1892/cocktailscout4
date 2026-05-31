require "rails_helper"

RSpec.describe WikiArticle, type: :model do
  describe "Associations" do
    it { should have_many(:ingredients).dependent(:nullify) }
  end

  describe "dependent: :nullify on ingredients" do
    it "nullifies ingredient wiki_article_id when article is destroyed" do
      article = create(:wiki_article)
      ingredient = create(:ingredient, wiki_article: article)

      article.destroy

      expect(ingredient.reload.wiki_article_id).to be_nil
    end
  end

  describe "#linked_recipes" do
    let(:article) { create(:wiki_article) }
    let(:ingredient) { create(:ingredient, wiki_article: article) }
    let(:other_ingredient) { create(:ingredient) }
    let!(:linked_recipe) { create(:recipe) }
    let!(:unlinked_recipe) { create(:recipe) }
    let!(:draft_recipe) { create(:recipe, :draft) }

    before do
      create(:recipe_ingredient, recipe: linked_recipe, ingredient: ingredient)
      create(:recipe_ingredient, recipe: unlinked_recipe, ingredient: other_ingredient)
      create(:recipe_ingredient, recipe: draft_recipe, ingredient: ingredient)
    end

    it "returns visible recipes using the linked ingredients" do
      expect(article.linked_recipes).to include(linked_recipe)
    end

    it "excludes recipes that don't use linked ingredients" do
      expect(article.linked_recipes).not_to include(unlinked_recipe)
    end

    it "excludes non-visible recipes" do
      expect(article.linked_recipes).not_to include(draft_recipe)
    end

    it "returns Recipe.none when no ingredients are linked" do
      empty_article = create(:wiki_article)
      expect(empty_article.linked_recipes).to eq(Recipe.none)
    end
  end

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
