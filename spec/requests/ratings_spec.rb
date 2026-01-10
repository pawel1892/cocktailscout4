require 'rails_helper'

RSpec.describe "Ratings API", type: :request do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe) }

  # Helper method to authenticate requests
  def sign_in(user)
    @session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")
    # Stub the authentication check to set Current.session for each request
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_wrap_original do |original_method, *args|
      Current.session = @session
      @session
    end
  end

  describe "POST /rate" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a new rating" do
        expect {
          post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 8 }
        }.to change { Rating.count }.by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["rating"]["score"]).to eq(8)
        expect(json["average"].to_f).to eq(8.0)
        expect(json["count"]).to eq(1)
      end

      it "updates an existing rating" do
        Rating.create!(user: user, rateable: recipe, score: 5)

        expect {
          post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 9 }
        }.not_to change { Rating.count }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["rating"]["score"]).to eq(9)
        expect(json["average"].to_f).to eq(9.0)
        expect(json["count"]).to eq(1)
      end

      it "returns the updated average and count with multiple ratings" do
        other_user = create(:user)
        Rating.create!(user: other_user, rateable: recipe, score: 6)

        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 8 }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["average"].to_f).to eq(7.0) # (6 + 8) / 2
        expect(json["count"]).to eq(2)
      end

      it "accepts valid scores from 1 to 10" do
        [1, 5, 10].each do |score|
          recipe_for_score = create(:recipe)
          post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe_for_score.id, score: score }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
        end
      end

      it "rejects invalid score below 1" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 0 }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "rejects invalid score above 10" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 11 }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "rejects decimal scores" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 5.5 }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "rejects missing score parameter" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "rejects invalid rateable_type" do
        expect {
          post rate_path, params: { rateable_type: "User", rateable_id: user.id, score: 8 }
        }.to raise_error(NameError, "Invalid rateable type")
      end

      it "returns 404 for non-existent recipe" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: 99999, score: 8 }

        expect(response).to have_http_status(:not_found)
      end

      it "updates the recipe's rating cache" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 7 }

        recipe.reload
        expect(recipe.average_rating).to eq(7.0)
        expect(recipe.ratings_count).to eq(1)
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 8 }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a rating" do
        expect {
          post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 8 }
        }.not_to change { Rating.count }
      end
    end
  end

  describe "DELETE /rate" do
    context "when authenticated" do
      before { sign_in(user) }

      it "deletes an existing rating" do
        Rating.create!(user: user, rateable: recipe, score: 8)

        expect {
          delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }
        }.to change { Rating.count }.by(-1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["average"].to_f).to eq(0.0)
        expect(json["count"]).to eq(0)
      end

      it "updates the average after deletion" do
        other_user = create(:user)
        Rating.create!(user: user, rateable: recipe, score: 8)
        Rating.create!(user: other_user, rateable: recipe, score: 6)

        delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["average"].to_f).to eq(6.0)
        expect(json["count"]).to eq(1)
      end

      it "returns 404 when rating does not exist" do
        delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Rating not found")
      end

      it "does not delete other users' ratings" do
        other_user = create(:user)
        other_rating = Rating.create!(user: other_user, rateable: recipe, score: 8)

        delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

        expect(response).to have_http_status(:not_found)
        expect(Rating.exists?(other_rating.id)).to be true
      end

      it "updates the recipe's rating cache after deletion" do
        Rating.create!(user: user, rateable: recipe, score: 8)

        delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

        recipe.reload
        expect(recipe.average_rating).to eq(0.0)
        expect(recipe.ratings_count).to eq(0)
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        Rating.create!(user: user, rateable: recipe, score: 8)

        delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not delete the rating" do
        rating = Rating.create!(user: user, rateable: recipe, score: 8)

        expect {
          delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }
        }.not_to change { Rating.count }

        expect(Rating.exists?(rating.id)).to be true
      end
    end
  end

  describe "user isolation" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "allows different users to rate the same recipe independently" do
      sign_in(user1)
      post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 8 }

      # Switch to user2
      sign_in(user2)
      post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 6 }

      expect(Rating.count).to eq(2)
      expect(Rating.find_by(user: user1).score).to eq(8)
      expect(Rating.find_by(user: user2).score).to eq(6)
    end

    it "only allows users to update their own ratings" do
      Rating.create!(user: user1, rateable: recipe, score: 8)

      sign_in(user2)
      post rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id, score: 10 }

      expect(Rating.count).to eq(2)
      expect(Rating.find_by(user: user1).score).to eq(8) # Unchanged
      expect(Rating.find_by(user: user2).score).to eq(10)
    end

    it "only allows users to delete their own ratings" do
      rating1 = Rating.create!(user: user1, rateable: recipe, score: 8)
      rating2 = Rating.create!(user: user2, rateable: recipe, score: 6)

      sign_in(user1)
      delete rate_path, params: { rateable_type: "Recipe", rateable_id: recipe.id }

      expect(Rating.exists?(rating1.id)).to be false
      expect(Rating.exists?(rating2.id)).to be true
    end
  end
end
