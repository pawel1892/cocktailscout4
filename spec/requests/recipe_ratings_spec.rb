require 'rails_helper'

RSpec.describe "Recipe Ratings Page", type: :request do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe) }

  def rating_data
    start_marker = "window.ratingDistribution = "
    end_marker   = ";</script>"
    body         = response.body
    start_idx    = body.index(start_marker) + start_marker.length
    end_idx      = body.index(end_marker, start_idx)
    JSON.parse(body[start_idx...end_idx])
  end

  describe "GET /rezepte/:slug/bewertungen" do
    context "page access" do
      it "is publicly accessible without authentication" do
        get bewertungen_recipe_path(recipe)
        expect(response).to have_http_status(:success)
      end

      it "is accessible when authenticated" do
        sign_in(user)
        get bewertungen_recipe_path(recipe)
        expect(response).to have_http_status(:success)
      end

      it "returns 404 for an unknown slug" do
        get bewertungen_recipe_path(slug: "non-existent-slug")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "response data structure" do
      it "includes top-level keys" do
        get bewertungen_recipe_path(recipe)

        data = rating_data
        expect(data).to have_key("total")
        expect(data).to have_key("average")
        expect(data).to have_key("distribution")
        expect(data).to have_key("recent")
      end

      it "distribution always contains 10 rows ordered 10 downto 1" do
        get bewertungen_recipe_path(recipe)

        distribution = rating_data["distribution"]
        expect(distribution.length).to eq(10)
        expect(distribution.map { |r| r["score"] }).to eq(10.downto(1).to_a)
      end
    end

    context "recipe with no ratings" do
      it "sets total to 0 and average to 0" do
        get bewertungen_recipe_path(recipe)

        data = rating_data
        expect(data["total"]).to eq(0)
        expect(data["average"].to_f).to eq(0.0)
      end

      it "returns empty recent array" do
        get bewertungen_recipe_path(recipe)
        expect(rating_data["recent"]).to be_empty
      end

      it "returns all distribution scores with zero count" do
        get bewertungen_recipe_path(recipe)

        rating_data["distribution"].each do |row|
          expect(row["count"]).to eq(0)
          expect(row["users"]).to be_empty
        end
      end
    end

    context "distribution" do
      it "counts ratings per score correctly" do
        other_user = create(:user)
        create(:rating, user: user,       rateable: recipe, score: 8)
        create(:rating, user: other_user, rateable: recipe, score: 8)
        create(:rating, user: create(:user), rateable: recipe, score: 5)

        get bewertungen_recipe_path(recipe)

        distribution = rating_data["distribution"]
        expect(distribution.find { |r| r["score"] == 8 }["count"]).to eq(2)
        expect(distribution.find { |r| r["score"] == 5 }["count"]).to eq(1)
        expect(distribution.find { |r| r["score"] == 1 }["count"]).to eq(0)
      end

      it "calculates percentages correctly" do
        create(:rating, user: create(:user), rateable: recipe, score: 10)
        create(:rating, user: create(:user), rateable: recipe, score: 10)
        create(:rating, user: create(:user), rateable: recipe, score: 5)
        create(:rating, user: create(:user), rateable: recipe, score: 5)

        get bewertungen_recipe_path(recipe)

        distribution = rating_data["distribution"]
        expect(distribution.find { |r| r["score"] == 10 }["percentage"]).to eq(50.0)
        expect(distribution.find { |r| r["score"] == 5  }["percentage"]).to eq(50.0)
      end

      it "includes user details for each score bucket" do
        create(:rating, user: user, rateable: recipe, score: 7)

        get bewertungen_recipe_path(recipe)

        score7 = rating_data["distribution"].find { |r| r["score"] == 7 }
        expect(score7["users"].length).to eq(1)
        expect(score7["users"].first["username"]).to eq(user.username)
        expect(score7["users"].first["id"]).to eq(user.id)
      end

      it "reflects the recipe average" do
        create(:rating, user: create(:user), rateable: recipe, score: 8)
        create(:rating, user: create(:user), rateable: recipe, score: 6)
        recipe.reload

        get bewertungen_recipe_path(recipe)

        expect(rating_data["average"].to_f).to eq(recipe.average_rating)
      end
    end

    context "recent ratings" do
      it "includes ratings updated within the last year" do
        create(:rating, user: user, rateable: recipe, score: 7, updated_at: 1.month.ago)

        get bewertungen_recipe_path(recipe)

        recent = rating_data["recent"]
        expect(recent.length).to eq(1)
        expect(recent.first["score"]).to eq(7)
        expect(recent.first["username"]).to eq(user.username)
      end

      it "excludes ratings not updated in the last year" do
        create(:rating, user: user, rateable: recipe, score: 8, updated_at: 13.months.ago)

        get bewertungen_recipe_path(recipe)

        expect(rating_data["recent"]).to be_empty
      end

      it "formats the date as dd.mm.yyyy from updated_at" do
        target_date = 1.month.ago
        create(:rating, user: user, rateable: recipe, score: 5, updated_at: target_date)

        get bewertungen_recipe_path(recipe)

        expect(rating_data["recent"].first["updated_at"]).to eq(target_date.strftime("%d.%m.%Y"))
      end

      it "limits to 20" do
        21.times { create(:rating, user: create(:user), rateable: recipe, score: 5, updated_at: 1.week.ago) }

        get bewertungen_recipe_path(recipe)

        expect(rating_data["recent"].length).to eq(20)
      end

      it "orders by updated_at newest first" do
        older_user = create(:user)
        newer_user = create(:user)
        create(:rating, user: older_user, rateable: recipe, score: 3, updated_at: 6.months.ago)
        create(:rating, user: newer_user, rateable: recipe, score: 9, updated_at: 1.week.ago)

        get bewertungen_recipe_path(recipe)

        recent = rating_data["recent"]
        expect(recent.first["username"]).to eq(newer_user.username)
        expect(recent.last["username"]).to eq(older_user.username)
      end

      it "includes user_id, rank and online fields" do
        create(:rating, user: user, rateable: recipe, score: 8, updated_at: 1.week.ago)

        get bewertungen_recipe_path(recipe)

        entry = rating_data["recent"].first
        expect(entry).to have_key("user_id")
        expect(entry).to have_key("rank")
        expect(entry).to have_key("online")
      end
    end
  end
end
