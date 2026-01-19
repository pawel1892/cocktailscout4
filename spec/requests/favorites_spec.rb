require 'rails_helper'

RSpec.describe "Favorites API", type: :request do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe) }

  describe "POST /favorite" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a new favorite" do
        expect {
          post favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }
        }.to change { Favorite.count }.by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["favorited"]).to be true
      end

      it "does not duplicate favorites" do
        Favorite.create!(user: user, favoritable: recipe)

        expect {
          post favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }
        }.not_to change { Favorite.count }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["favorited"]).to be true
      end

      it "rejects invalid favoritable_type" do
        post favorite_path, params: { favoritable_type: "User", favoritable_id: user.id }

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent recipe" do
        post favorite_path, params: { favoritable_type: "Recipe", favoritable_id: 99999 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        post favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a favorite" do
        expect {
          post favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }
        }.not_to change { Favorite.count }
      end
    end
  end

  describe "DELETE /favorite" do
    context "when authenticated" do
      before { sign_in(user) }

      it "deletes an existing favorite" do
        Favorite.create!(user: user, favoritable: recipe)

        expect {
          delete favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }
        }.to change { Favorite.count }.by(-1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["favorited"]).to be false
      end

      it "returns 404 when favorite does not exist" do
        delete favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Favorite not found")
      end

      it "does not delete other users' favorites" do
        other_user = create(:user)
        other_favorite = Favorite.create!(user: other_user, favoritable: recipe)

        delete favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }

        expect(response).to have_http_status(:not_found)
        expect(Favorite.exists?(other_favorite.id)).to be true
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        Favorite.create!(user: user, favoritable: recipe)

        delete favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not delete the favorite" do
        favorite = Favorite.create!(user: user, favoritable: recipe)

        expect {
          delete favorite_path, params: { favoritable_type: "Recipe", favoritable_id: recipe.id }
        }.not_to change { Favorite.count }

        expect(Favorite.exists?(favorite.id)).to be true
      end
    end
  end
end
