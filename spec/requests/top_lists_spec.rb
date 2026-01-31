require 'rails_helper'

RSpec.describe "TopLists", type: :request do
  describe "GET /toplisten" do
    it "returns http success" do
      get top_lists_path
      expect(response).to have_http_status(:success)
    end

    it "displays the page title" do
      get top_lists_path
      expect(response.body).to include("Toplisten")
    end

    it "is accessible without authentication" do
      get top_lists_path
      expect(response).to have_http_status(:success)
      expect(response).not_to redirect_to(new_session_path)
    end

    context "when there are no recipes" do
      it "displays empty lists" do
        get top_lists_path
        expect(response).to have_http_status(:success)
        # Should still show category headers
        expect(response.body).to include("Wodka-Drinks")
        expect(response.body).to include("Gin-Drinks")
      end
    end

    context "when there are tagged recipes" do
      let!(:gin_recipe_1) { create(:recipe, average_rating: 9.5, ratings_count: 10) }
      let!(:gin_recipe_2) { create(:recipe, average_rating: 8.5, ratings_count: 5) }
      let!(:gin_recipe_3) { create(:recipe, average_rating: 7.0, ratings_count: 3) }
      let!(:rum_recipe) { create(:recipe, average_rating: 9.0, ratings_count: 8) }

      before do
        gin_recipe_1.tag_list.add("gin")
        gin_recipe_1.save
        gin_recipe_2.tag_list.add("gin")
        gin_recipe_2.save
        gin_recipe_3.tag_list.add("gin")
        gin_recipe_3.save
        rum_recipe.tag_list.add("rum")
        rum_recipe.save
      end

      it "displays recipes in the correct categories" do
        get top_lists_path
        expect(response.body).to include("Gin-Drinks")
        expect(response.body).to include("Rum-Drinks")
        expect(response.body).to include(gin_recipe_1.title)
        expect(response.body).to include(rum_recipe.title)
      end

      it "orders recipes by rating descending" do
        get top_lists_path
        # In the Gin-Drinks section, highest rated should appear first
        # Check order in full response body
        pos_1 = response.body.index(gin_recipe_1.title)
        pos_2 = response.body.index(gin_recipe_2.title)
        pos_3 = response.body.index(gin_recipe_3.title)

        # All should be present
        expect(pos_1).to be_present
        expect(pos_2).to be_present
        expect(pos_3).to be_present

        # And in correct order (highest rating first)
        expect(pos_1).to be < pos_2
        expect(pos_2).to be < pos_3
      end

      it "displays rating badges" do
        get top_lists_path
        # Ratings are formatted with comma separator
        expect(response.body).to include("9,5")
        expect(response.body).to include("9,0")
      end

      it "limits results to 10 per category" do
        # Create 12 gin recipes (plus 3 existing = 15 total)
        12.times do |i|
          recipe = create(:recipe, average_rating: 8.0 - i * 0.1, ratings_count: 5)
          recipe.tag_list.add("gin")
          recipe.save
        end

        get top_lists_path

        # Extract the Gin-Drinks table section
        gin_section_match = response.body.match(/Top 10 Gin-Drinks.*?<\/table>/m)
        expect(gin_section_match).to be_present

        # Count <tr> elements with recipe links (exclude header row)
        recipe_rows = gin_section_match[0].scan(/<tr[^>]*>.*?href="\/rezepte\//m).length
        expect(recipe_rows).to eq(10)
      end
    end

    context "with multiple categories" do
      before do
        # Create recipes for different categories
        %w[wodka gin rum tequila].each do |tag|
          recipe = create(:recipe, average_rating: 9.0)
          recipe.tag_list.add(tag)
          recipe.save
        end
      end

      it "displays all 15 category sections" do
        get top_lists_path
        expect(response.body).to include("Wodka-Drinks")
        expect(response.body).to include("Gin-Drinks")
        expect(response.body).to include("Tequila-Drinks")
        expect(response.body).to include("Whiskey-Drinks")
        expect(response.body).to include("Rum-Drinks")
        expect(response.body).to include("Erfrischend")
        expect(response.body).to include("Fruchtig")
        expect(response.body).to include("Alkoholfrei")
      end
    end

    context "with recipes having same rating" do
      let!(:recipe_a) { create(:recipe, average_rating: 9.0, ratings_count: 10) }
      let!(:recipe_b) { create(:recipe, average_rating: 9.0, ratings_count: 5) }

      before do
        recipe_a.tag_list.add("gin")
        recipe_a.save
        recipe_b.tag_list.add("gin")
        recipe_b.save
      end

      it "uses ratings_count as secondary sort" do
        get top_lists_path

        # Recipe with more ratings should come first
        pos_a = response.body.index(recipe_a.title)
        pos_b = response.body.index(recipe_b.title)

        expect(pos_a).to be_present
        expect(pos_b).to be_present
        expect(pos_a).to be < pos_b
      end
    end
  end
end
