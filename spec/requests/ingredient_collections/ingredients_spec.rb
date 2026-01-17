require 'rails_helper'

RSpec.describe "Ingredient Collections::Ingredients API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:collection) { create(:ingredient_collection, user: user, name: "Home Bar") }
  let(:vodka) { create(:ingredient, name: "Vodka") }
  let(:gin) { create(:ingredient, name: "Gin") }
  let(:rum) { create(:ingredient, name: "Rum") }

  describe "POST /ingredient_collections/:ingredient_collection_id/ingredients" do
    context "when authenticated" do
      before { sign_in(user) }

      context "adding single ingredient" do
        it "adds ingredient to collection" do
          post ingredient_collection_ingredients_path(collection), params: { ingredient_id: vodka.id }

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["added"].size).to eq(1)
          expect(json["added"].first["name"]).to eq("Vodka")
          expect(json["collection"]["ingredient_count"]).to eq(1)
          expect(collection.reload.ingredients).to include(vodka)
        end

        it "returns updated collection with all ingredients" do
          collection.ingredients << gin

          post ingredient_collection_ingredients_path(collection), params: { ingredient_id: vodka.id }

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["collection"]["ingredients"].size).to eq(2)
          expect(json["collection"]["ingredients"].map { |i| i["name"] }).to contain_exactly("Vodka", "Gin")
        end

        it "returns error when ingredient already in collection" do
          collection.ingredients << vodka

          post ingredient_collection_ingredients_path(collection), params: { ingredient_id: vodka.id }

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["errors"]).to include("Ingredient 'Vodka' already in collection")
          expect(json["added"]).to eq([])
        end

        it "returns error when ingredient does not exist" do
          post ingredient_collection_ingredients_path(collection), params: { ingredient_id: 99999 }

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["errors"]).to include("Ingredient 99999 not found")
        end

        it "returns bad request when no ingredient_id provided" do
          post ingredient_collection_ingredients_path(collection), params: {}

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["error"]).to eq("No ingredient_id or ingredient_ids provided")
        end
      end

      context "adding multiple ingredients" do
        it "adds multiple ingredients to collection" do
          post ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ vodka.id, gin.id, rum.id ] }

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["added"].size).to eq(3)
          expect(json["added"].map { |i| i["name"] }).to contain_exactly("Vodka", "Gin", "Rum")
          expect(collection.reload.ingredients.count).to eq(3)
        end

        it "handles partial success - adds valid ingredients and reports errors" do
          collection.ingredients << gin

          post ingredient_collection_ingredients_path(collection), params: {
            ingredient_ids: [ vodka.id, gin.id, 99999 ]
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["added"].size).to eq(1) # Only vodka added
          expect(json["added"].first["name"]).to eq("Vodka")
          expect(json["errors"]).to include("Ingredient 'Gin' already in collection")
          expect(json["errors"]).to include("Ingredient 99999 not found")
          expect(collection.reload.ingredients.count).to eq(2) # gin (existing) + vodka (added)
        end

        it "handles duplicate ids in request" do
          post ingredient_collection_ingredients_path(collection), params: {
            ingredient_ids: [ vodka.id, vodka.id ]
          }

          json = JSON.parse(response.body)
          expect(json["added"].size).to eq(1)
          expect(json["errors"]).to include("Ingredient 'Vodka' already in collection")
        end
      end

      it "returns 404 for non-existent collection" do
        post ingredient_collection_ingredients_path(ingredient_collection_id: 99999), params: { ingredient_id: vodka.id }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Collection not found")
      end

      it "returns 404 for other user's collection" do
        other_collection = create(:ingredient_collection, user: other_user)

        post ingredient_collection_ingredients_path(other_collection), params: { ingredient_id: vodka.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        post ingredient_collection_ingredients_path(collection), params: { ingredient_id: vodka.id }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not add ingredient to collection" do
        expect {
          post ingredient_collection_ingredients_path(collection), params: { ingredient_id: vodka.id }
        }.not_to change { collection.ingredients.count }
      end
    end
  end

  describe "DELETE /ingredient_collections/:ingredient_collection_id/ingredients/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "removes ingredient from collection" do
        collection.ingredients << [ vodka, gin ]

        delete ingredient_collection_ingredient_path(collection, vodka)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["removed"]["name"]).to eq("Vodka")
        expect(json["collection"]["ingredient_count"]).to eq(1)
        expect(collection.reload.ingredients).not_to include(vodka)
        expect(collection.reload.ingredients).to include(gin)
      end

      it "returns updated collection after removal" do
        collection.ingredients << [ vodka, gin, rum ]

        delete ingredient_collection_ingredient_path(collection, gin)

        json = JSON.parse(response.body)
        expect(json["collection"]["ingredients"].size).to eq(2)
        expect(json["collection"]["ingredients"].map { |i| i["name"] }).to contain_exactly("Vodka", "Rum")
      end

      it "returns 404 when ingredient not in collection" do
        delete ingredient_collection_ingredient_path(collection, vodka)

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Ingredient not found in this collection")
      end

      it "does not delete the ingredient itself" do
        collection.ingredients << vodka

        expect {
          delete ingredient_collection_ingredient_path(collection, vodka)
        }.not_to change { Ingredient.count }

        expect(Ingredient.exists?(vodka.id)).to be true
      end

      it "returns 404 for other user's collection" do
        other_collection = create(:ingredient_collection, user: other_user)
        other_collection.ingredients << vodka

        delete ingredient_collection_ingredient_path(other_collection, vodka)

        expect(response).to have_http_status(:not_found)
        expect(other_collection.reload.ingredients).to include(vodka)
      end
    end

    context "when not authenticated" do
      before { collection.ingredients << vodka }

      it "redirects to login page" do
        delete ingredient_collection_ingredient_path(collection, vodka)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not remove ingredient from collection" do
        expect {
          delete ingredient_collection_ingredient_path(collection, vodka)
        }.not_to change { collection.reload.ingredients.count }
      end
    end
  end

  describe "PUT /ingredient_collections/:ingredient_collection_id/ingredients" do
    context "when authenticated" do
      before { sign_in(user) }

      it "replaces all ingredients in collection" do
        collection.ingredients << [ vodka, gin ]

        put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ rum.id ] }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["collection"]["ingredient_count"]).to eq(1)
        expect(collection.reload.ingredients).to contain_exactly(rum)
      end

      it "can replace with multiple ingredients" do
        collection.ingredients << vodka

        put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ gin.id, rum.id ] }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collection"]["ingredients"].size).to eq(2)
        expect(collection.reload.ingredients).to contain_exactly(gin, rum)
      end

      it "can empty the collection" do
        collection.ingredients << [ vodka, gin ]

        # Empty array will be stripped by Rails params, so we need to send it explicitly
        put ingredient_collection_ingredients_path(collection),
            params: { ingredient_ids: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collection"]["ingredient_count"]).to eq(0)
        expect(collection.reload.ingredients).to be_empty
      end

      it "handles duplicate ids by deduplicating" do
        put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ vodka.id, vodka.id, gin.id ] }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collection"]["ingredient_count"]).to eq(2)
        expect(collection.reload.ingredients).to contain_exactly(vodka, gin)
      end

      it "returns error if any ingredient does not exist" do
        put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ vodka.id, 99999 ] }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to match(/Ingredients not found:.*99999/)
      end

      it "does not modify collection if validation fails" do
        collection.ingredients << [ vodka, gin ]
        original_ingredients = collection.ingredients.to_a

        put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ 99999 ] }

        expect(collection.reload.ingredients).to match_array(original_ingredients)
      end

      it "returns 404 for other user's collection" do
        other_collection = create(:ingredient_collection, user: other_user)
        other_collection.ingredients << vodka

        put ingredient_collection_ingredients_path(other_collection), params: { ingredient_ids: [ gin.id ] }

        expect(response).to have_http_status(:not_found)
        expect(other_collection.reload.ingredients).to contain_exactly(vodka)
      end
    end

    context "when not authenticated" do
      before { collection.ingredients << vodka }

      it "redirects to login page" do
        put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ gin.id ] }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not modify collection" do
        expect {
          put ingredient_collection_ingredients_path(collection), params: { ingredient_ids: [ gin.id ] }
        }.not_to change { collection.reload.ingredients.to_a }
      end
    end
  end

  describe "user isolation for ingredients" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:collection1) { create(:ingredient_collection, user: user1) }
    let(:collection2) { create(:ingredient_collection, user: user2) }

    it "users can add same ingredient to their own collections" do
      sign_in(user1)
      post ingredient_collection_ingredients_path(collection1), params: { ingredient_id: vodka.id }

      sign_in(user2)
      post ingredient_collection_ingredients_path(collection2), params: { ingredient_id: vodka.id }

      expect(collection1.reload.ingredients).to include(vodka)
      expect(collection2.reload.ingredients).to include(vodka)
    end

    it "users cannot modify other users' collection ingredients" do
      collection1.ingredients << vodka

      sign_in(user2)
      delete ingredient_collection_ingredient_path(collection1, vodka)

      expect(response).to have_http_status(:not_found)
      expect(collection1.reload.ingredients).to include(vodka)
    end

    it "users cannot replace ingredients in other users' collections" do
      collection1.ingredients << vodka

      sign_in(user2)
      put ingredient_collection_ingredients_path(collection1), params: { ingredient_ids: [ gin.id ] }

      expect(response).to have_http_status(:not_found)
      expect(collection1.reload.ingredients).to contain_exactly(vodka)
    end
  end
end
