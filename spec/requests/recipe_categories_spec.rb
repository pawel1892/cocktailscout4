require 'rails_helper'

RSpec.describe "RecipeCategories", type: :request do
  describe "GET /rezept-kategorien" do
    it "returns http success" do
      get recipe_categories_path
      expect(response).to have_http_status(:success)
    end

    it "displays the page title" do
      get recipe_categories_path
      expect(response.body).to include("Rezept-Kategorien")
    end

    context "when there are no tags" do
      it "shows an empty tag cloud" do
        get recipe_categories_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Keine Kategorien gefunden")
      end
    end

    context "when there are tags" do
      let!(:recipe1) { create(:recipe) }
      let!(:recipe2) { create(:recipe) }
      let!(:recipe3) { create(:recipe) }

      before do
        recipe1.tag_list.add("Rum")
        recipe1.save
        recipe2.tag_list.add("Rum", "Fruity")
        recipe2.save
        recipe3.tag_list.add("Gin")
        recipe3.save
      end

      it "displays all tags" do
        get recipe_categories_path
        expect(response.body).to include("Rum")
        expect(response.body).to include("Fruity")
        expect(response.body).to include("Gin")
      end

      it "displays tags in alphabetical order" do
        get recipe_categories_path
        # Tags should appear in order: Fruity, Gin, Rum
        expect(response.body).to match(/Fruity.*Gin.*Rum/m)
      end

      it "links to tag filter page" do
        get recipe_categories_path
        # Links should go to /tag/:tag_name
        expect(response.body).to include(tag_path(tag: "Rum"))
        expect(response.body).to include(tag_path(tag: "Gin"))
      end

      it "shows tooltip with recipe count" do
        get recipe_categories_path
        # Rum has 2 recipes
        expect(response.body).to include('title="2 Rezepte"')
        # Gin and Fruity have 1 recipe each
        expect(response.body).to include('title="1 Rezept"')
      end

      it "assigns different CSS classes based on tag count" do
        get recipe_categories_path
        # Rum has 2 recipes, should get one level
        # Gin and Fruity have 1 recipe each, should get another level
        # Check for tag-level-* classes
        expect(response.body).to match(/tag-level-\d+/)
      end
    end

    context "with many recipes per tag" do
      before do
        # Create tags with varying counts to test logarithmic distribution
        10.times do |i|
          recipe = create(:recipe)
          recipe.tag_list.add("Popular")
          recipe.save
        end

        3.times do |i|
          recipe = create(:recipe)
          recipe.tag_list.add("Medium")
          recipe.save
        end

        recipe = create(:recipe)
        recipe.tag_list.add("Rare")
        recipe.save
      end

      it "displays all tag categories" do
        get recipe_categories_path
        expect(response.body).to include("Popular")
        expect(response.body).to include("Medium")
        expect(response.body).to include("Rare")
      end

      it "shows correct recipe counts in tooltips" do
        get recipe_categories_path
        expect(response.body).to include('title="10 Rezepte"')
        expect(response.body).to include('title="3 Rezepte"')
        expect(response.body).to include('title="1 Rezept"')
      end
    end

    context "visibility filtering" do
      let!(:visible_recipe) { create(:recipe) }
      let!(:deleted_recipe) { create(:recipe, :deleted) }
      let!(:draft_recipe)   { create(:recipe, :draft) }

      before do
        visible_recipe.tag_list.add("VisibleTag")
        visible_recipe.save!
        deleted_recipe.tag_list.add("DeletedTag")
        deleted_recipe.save!
        draft_recipe.tag_list.add("DraftTag")
        draft_recipe.save!
      end

      it "shows only tags from visible recipes" do
        get recipe_categories_path
        expect(response.body).to include("VisibleTag")
        expect(response.body).not_to include("DeletedTag")
        expect(response.body).not_to include("DraftTag")
      end

      it "counts only taggings from visible recipes" do
        visible_recipe2 = create(:recipe)
        visible_recipe2.tag_list.add("VisibleTag")
        visible_recipe2.save!
        deleted_recipe.tag_list.add("VisibleTag")
        deleted_recipe.save!

        get recipe_categories_path
        expect(response.body).to include('title="2 Rezepte"')
        expect(response.body).not_to include('title="3 Rezepte"')
      end
    end

    it "is accessible without authentication" do
      get recipe_categories_path
      expect(response).to have_http_status(:success)
      expect(response).not_to redirect_to(new_session_path)
    end
  end
end
