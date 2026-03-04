require 'rails_helper'

RSpec.describe "User Ratings Page", type: :request do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe) }

  # Extracts the JSON object injected into window.userRatingData from the rendered HTML
  def user_rating_data
    start_marker = "window.userRatingData = "
    end_marker   = ";</script>"
    body         = response.body
    start_idx    = body.index(start_marker) + start_marker.length
    end_idx      = body.index(end_marker, start_idx)
    JSON.parse(body[start_idx...end_idx])
  end

  describe "GET /benutzer/:id/bewertungen" do
    context "page access" do
      it "is publicly accessible without authentication" do
        get bewertungen_user_path(user)
        expect(response).to have_http_status(:success)
      end

      it "is accessible when authenticated" do
        sign_in(user)
        get bewertungen_user_path(user)
        expect(response).to have_http_status(:success)
      end

      it "returns 404 for a non-existent user" do
        get bewertungen_user_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "response data structure" do
      it "includes top-level keys with correct user info" do
        get bewertungen_user_path(user)

        data = user_rating_data
        expect(data["username"]).to eq(user.username)
        expect(data["user_id"]).to eq(user.id)
        expect(data).to have_key("total")
        expect(data).to have_key("recent")
        expect(data).to have_key("distribution")
        expect(data).to have_key("unrated")
      end

      it "distribution always contains 10 rows ordered 10 downto 1" do
        get bewertungen_user_path(user)

        distribution = user_rating_data["distribution"]
        expect(distribution.length).to eq(10)
        expect(distribution.map { |r| r["score"] }).to eq((10.downto(1).to_a))
      end
    end

    context "user with no ratings" do
      it "sets total to 0" do
        get bewertungen_user_path(user)
        expect(user_rating_data["total"]).to eq(0)
      end

      it "returns empty recent array" do
        get bewertungen_user_path(user)
        expect(user_rating_data["recent"]).to be_empty
      end

      it "returns all distribution scores with zero count and percentage" do
        get bewertungen_user_path(user)

        user_rating_data["distribution"].each do |row|
          expect(row["count"]).to eq(0)
          expect(row["percentage"]).to eq(0)
          expect(row["recipes"]).to be_empty
        end
      end

      it "includes all visible recipes in unrated" do
        visible1 = create(:recipe)
        visible2 = create(:recipe)

        get bewertungen_user_path(user)

        unrated_slugs = user_rating_data["unrated"].map { |r| r["slug"] }
        expect(unrated_slugs).to include(visible1.slug, visible2.slug)
      end
    end

    context "section 1: recent ratings" do
      it "includes ratings updated within the last year" do
        recent_recipe = create(:recipe)
        create(:rating, user: user, rateable: recent_recipe, score: 7,
               updated_at: 1.month.ago)

        get bewertungen_user_path(user)

        recent = user_rating_data["recent"]
        expect(recent.length).to eq(1)
        expect(recent.first["score"]).to eq(7)
        expect(recent.first["recipe_slug"]).to eq(recent_recipe.slug)
      end

      it "excludes ratings not updated in the last year" do
        old_recipe = create(:recipe)
        create(:rating, user: user, rateable: old_recipe, score: 8,
               updated_at: 13.months.ago)

        get bewertungen_user_path(user)

        expect(user_rating_data["recent"]).to be_empty
      end

      it "formats the date as dd.mm.yyyy from updated_at" do
        target_date = 1.month.ago
        create(:rating, user: user, rateable: recipe, score: 5, updated_at: target_date)

        get bewertungen_user_path(user)

        expect(user_rating_data["recent"].first["updated_at"]).to eq(target_date.strftime("%d.%m.%Y"))
      end

      it "limits to 20" do
        recipes = create_list(:recipe, 21)
        recipes.each_with_index do |r, i|
          create(:rating, user: user, rateable: r, score: 5,
                 updated_at: i.days.ago)
        end

        get bewertungen_user_path(user)

        expect(user_rating_data["recent"].length).to eq(20)
      end

      it "orders by updated_at newest first" do
        older_recipe = create(:recipe)
        newer_recipe = create(:recipe)
        create(:rating, user: user, rateable: older_recipe, score: 3,
               updated_at: 6.months.ago)
        create(:rating, user: user, rateable: newer_recipe, score: 9,
               updated_at: 1.week.ago)

        get bewertungen_user_path(user)

        recent = user_rating_data["recent"]
        expect(recent.first["recipe_slug"]).to eq(newer_recipe.slug)
        expect(recent.last["recipe_slug"]).to eq(older_recipe.slug)
      end
    end

    context "section 2: distribution" do
      it "counts ratings per score correctly" do
        r1 = create(:recipe)
        r2 = create(:recipe)
        r3 = create(:recipe)
        create(:rating, user: user, rateable: r1, score: 8)
        create(:rating, user: user, rateable: r2, score: 8)
        create(:rating, user: user, rateable: r3, score: 5)

        get bewertungen_user_path(user)

        distribution = user_rating_data["distribution"]
        score8 = distribution.find { |r| r["score"] == 8 }
        score5 = distribution.find { |r| r["score"] == 5 }
        score1 = distribution.find { |r| r["score"] == 1 }

        expect(score8["count"]).to eq(2)
        expect(score5["count"]).to eq(1)
        expect(score1["count"]).to eq(0)
      end

      it "calculates percentages correctly" do
        r1 = create(:recipe)
        r2 = create(:recipe)
        r3 = create(:recipe)
        r4 = create(:recipe)
        create(:rating, user: user, rateable: r1, score: 10)
        create(:rating, user: user, rateable: r2, score: 10)
        create(:rating, user: user, rateable: r3, score: 5)
        create(:rating, user: user, rateable: r4, score: 5)

        get bewertungen_user_path(user)

        distribution = user_rating_data["distribution"]
        score10 = distribution.find { |r| r["score"] == 10 }
        score5  = distribution.find { |r| r["score"] == 5 }

        expect(score10["percentage"]).to eq(50.0)
        expect(score5["percentage"]).to eq(50.0)
      end

      it "includes recipe details for each score bucket" do
        create(:rating, user: user, rateable: recipe, score: 7)

        get bewertungen_user_path(user)

        score7 = user_rating_data["distribution"].find { |r| r["score"] == 7 }
        expect(score7["recipes"].length).to eq(1)
        expect(score7["recipes"].first["slug"]).to eq(recipe.slug)
        expect(score7["recipes"].first["title"]).to eq(recipe.title)
        expect(score7["recipes"].first).to have_key("average_rating")
      end

      it "sets recipe_slug to nil for hard-deleted recipes" do
        create(:rating, user: user, rateable: recipe, score: 6)
        # Bypass dependent: :destroy to simulate a recipe deleted outside of AR
        Recipe.where(id: recipe.id).delete_all

        get bewertungen_user_path(user)

        score6 = user_rating_data["distribution"].find { |r| r["score"] == 6 }
        expect(score6["recipes"].first["slug"]).to be_nil
        expect(score6["recipes"].first["title"]).to be_nil
      end

      it "counts total ratings correctly" do
        r1 = create(:recipe)
        r2 = create(:recipe)
        r3 = create(:recipe)
        create(:rating, user: user, rateable: r1, score: 4)
        create(:rating, user: user, rateable: r2, score: 7)
        create(:rating, user: user, rateable: r3, score: 9)

        get bewertungen_user_path(user)

        expect(user_rating_data["total"]).to eq(3)
      end
    end

    context "section 3: unrated recipes" do
      it "excludes recipes the user has already rated" do
        unrated_recipe = create(:recipe)
        create(:rating, user: user, rateable: recipe, score: 5)

        get bewertungen_user_path(user)

        unrated_slugs = user_rating_data["unrated"].map { |r| r["slug"] }
        expect(unrated_slugs).to include(unrated_recipe.slug)
        expect(unrated_slugs).not_to include(recipe.slug)
      end

      it "excludes draft (non-public) recipes" do
        draft = create(:recipe, :draft)

        get bewertungen_user_path(user)

        unrated_slugs = user_rating_data["unrated"].map { |r| r["slug"] }
        expect(unrated_slugs).not_to include(draft.slug)
      end

      it "excludes soft-deleted recipes" do
        deleted = create(:recipe, :deleted)

        get bewertungen_user_path(user)

        unrated_slugs = user_rating_data["unrated"].map { |r| r["slug"] }
        expect(unrated_slugs).not_to include(deleted.slug)
      end

      it "sorts by title ascending" do
        recipe_c = create(:recipe, title: "Caipirinha")
        recipe_a = create(:recipe, title: "Aperol Spritz")
        recipe_b = create(:recipe, title: "Boulevardier")

        get bewertungen_user_path(user)

        unrated_titles = user_rating_data["unrated"].map { |r| r["title"] }
        expect(unrated_titles.index("Aperol Spritz")).to be < unrated_titles.index("Boulevardier")
        expect(unrated_titles.index("Boulevardier")).to be < unrated_titles.index("Caipirinha")
      end

      it "includes title, slug, average_rating and ratings_count for each recipe" do
        visible = create(:recipe, average_rating: 7.5, ratings_count: 3)

        get bewertungen_user_path(user)

        entry = user_rating_data["unrated"].find { |r| r["slug"] == visible.slug }
        expect(entry["title"]).to eq(visible.title)
        expect(entry["average_rating"].to_f).to eq(7.5)
        expect(entry["ratings_count"]).to eq(3)
      end
    end

    context "ratings from other users are not included" do
      it "only shows ratings by the requested user" do
        other_user = create(:user)
        other_recipe = create(:recipe)
        create(:rating, user: other_user, rateable: other_recipe, score: 9)
        create(:rating, user: user, rateable: recipe, score: 5)

        get bewertungen_user_path(user)

        data = user_rating_data
        expect(data["total"]).to eq(1)

        all_slugs_in_distribution = data["distribution"].flat_map { |r| r["recipes"].map { |rec| rec["slug"] } }
        expect(all_slugs_in_distribution).to include(recipe.slug)
        expect(all_slugs_in_distribution).not_to include(other_recipe.slug)
      end
    end
  end
end
