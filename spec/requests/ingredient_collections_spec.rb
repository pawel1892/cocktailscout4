require 'rails_helper'

RSpec.describe "Ingredient Collections API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /ingredient_collections" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns empty array when user has no collections" do
        get ingredient_collections_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["collections"]).to eq([])
      end

      it "returns all user's collections" do
        collection1 = create(:ingredient_collection, user: user, name: "Home Bar")
        collection2 = create(:ingredient_collection, user: user, name: "Party")

        get ingredient_collections_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["collections"].size).to eq(2)
        expect(json["collections"].map { |c| c["name"] }).to contain_exactly("Home Bar", "Party")
      end

      it "returns collections ordered by is_default desc, created_at asc" do
        collection1 = create(:ingredient_collection, user: user, name: "First")
        collection1.update_column(:is_default, false)

        collection2 = create(:ingredient_collection, user: user, name: "Default", is_default: true)

        collection3 = create(:ingredient_collection, user: user, name: "Third")
        collection3.update_column(:is_default, false)

        get ingredient_collections_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        names = json["collections"].map { |c| c["name"] }
        expect(names).to eq([ "Default", "First", "Third" ])
      end

      it "includes ingredient_count in response" do
        collection = create(:ingredient_collection, :with_ingredients, user: user, ingredients_count: 5)

        get ingredient_collections_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collections"].first["ingredient_count"]).to eq(5)
      end

      it "does not return other users' collections" do
        create(:ingredient_collection, user: user, name: "My Collection")
        create(:ingredient_collection, user: other_user, name: "Other Collection")

        get ingredient_collections_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collections"].size).to eq(1)
        expect(json["collections"].first["name"]).to eq("My Collection")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get ingredient_collections_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /ingredient_collections/:id" do
    let(:collection) { create(:ingredient_collection, user: user, name: "Home Bar") }

    context "when authenticated" do
      before { sign_in(user) }

      it "returns the collection with ingredients" do
        ingredient1 = create(:ingredient, name: "Vodka")
        ingredient2 = create(:ingredient, name: "Gin")
        collection.ingredients << [ ingredient1, ingredient2 ]

        get ingredient_collection_path(collection)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["collection"]["name"]).to eq("Home Bar")
        expect(json["collection"]["ingredients"].size).to eq(2)
        expect(json["collection"]["ingredients"].map { |i| i["name"] }).to contain_exactly("Vodka", "Gin")
      end

      it "returns 404 for non-existent collection" do
        get ingredient_collection_path(id: 99999)

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Collection not found")
      end

      it "returns 404 for other user's collection" do
        other_collection = create(:ingredient_collection, user: other_user)

        get ingredient_collection_path(other_collection)

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get ingredient_collection_path(collection)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /ingredient_collections" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a new collection" do
        expect {
          post ingredient_collections_path, params: { name: "Home Bar" }
        }.to change { IngredientCollection.count }.by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["collection"]["name"]).to eq("Home Bar")
      end

      it "creates collection with notes" do
        post ingredient_collections_path, params: { name: "Shopping", notes: "Buy vodka, gin" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["collection"]["notes"]).to eq("Buy vodka, gin")
      end

      it "sets first collection as default automatically" do
        post ingredient_collections_path, params: { name: "First Collection" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["collection"]["is_default"]).to be true
      end

      it "does not set second collection as default" do
        create(:ingredient_collection, user: user, is_default: true)

        post ingredient_collections_path, params: { name: "Second Collection" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["collection"]["is_default"]).to be false
      end

      it "returns validation errors for blank name" do
        post ingredient_collections_path, params: { name: "" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "returns validation errors for duplicate name" do
        create(:ingredient_collection, user: user, name: "Home Bar")

        post ingredient_collections_path, params: { name: "Home Bar" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "allows same name for different users" do
        create(:ingredient_collection, user: other_user, name: "Home Bar")

        post ingredient_collections_path, params: { name: "Home Bar" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        post ingredient_collections_path, params: { name: "Home Bar" }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a collection" do
        expect {
          post ingredient_collections_path, params: { name: "Home Bar" }
        }.not_to change { IngredientCollection.count }
      end
    end
  end

  describe "PATCH /ingredient_collections/:id" do
    let(:collection) { create(:ingredient_collection, user: user, name: "Old Name") }

    context "when authenticated" do
      before { sign_in(user) }

      it "updates the collection name" do
        patch ingredient_collection_path(collection), params: { name: "New Name" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["collection"]["name"]).to eq("New Name")
        expect(collection.reload.name).to eq("New Name")
      end

      it "updates the notes" do
        patch ingredient_collection_path(collection), params: { notes: "Updated notes" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collection"]["notes"]).to eq("Updated notes")
      end

      it "updates is_default" do
        patch ingredient_collection_path(collection), params: { is_default: true }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["collection"]["is_default"]).to be true
        expect(collection.reload.is_default).to be true
      end

      it "returns validation errors for invalid data" do
        create(:ingredient_collection, user: user, name: "Existing Name")

        patch ingredient_collection_path(collection), params: { name: "Existing Name" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["errors"]).to be_present
      end

      it "returns 404 for other user's collection" do
        other_collection = create(:ingredient_collection, user: other_user)

        patch ingredient_collection_path(other_collection), params: { name: "New Name" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        patch ingredient_collection_path(collection), params: { name: "New Name" }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /ingredient_collections/:id" do
    let!(:collection) { create(:ingredient_collection, user: user) }

    context "when authenticated" do
      before { sign_in(user) }

      it "deletes the collection" do
        expect {
          delete ingredient_collection_path(collection)
        }.to change { IngredientCollection.count }.by(-1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end

      it "deletes associated collection_ingredients" do
        collection.ingredients << create(:ingredient)

        expect {
          delete ingredient_collection_path(collection)
        }.to change { CollectionIngredient.count }.by(-1)
      end

      it "does not delete ingredients themselves" do
        ingredient = create(:ingredient)
        collection.ingredients << ingredient

        expect {
          delete ingredient_collection_path(collection)
        }.not_to change { Ingredient.count }

        expect(Ingredient.exists?(ingredient.id)).to be true
      end

      it "returns 404 for other user's collection" do
        other_collection = create(:ingredient_collection, user: other_user)

        delete ingredient_collection_path(other_collection)

        expect(response).to have_http_status(:not_found)
        expect(IngredientCollection.exists?(other_collection.id)).to be true
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        delete ingredient_collection_path(collection)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not delete the collection" do
        expect {
          delete ingredient_collection_path(collection)
        }.not_to change { IngredientCollection.count }
      end
    end
  end

  describe "user isolation" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "users can only see their own collections" do
      collection1 = create(:ingredient_collection, user: user1, name: "User1 Collection")
      collection2 = create(:ingredient_collection, user: user2, name: "User2 Collection")

      sign_in(user1)
      get ingredient_collections_path

      json = JSON.parse(response.body)
      expect(json["collections"].size).to eq(1)
      expect(json["collections"].first["name"]).to eq("User1 Collection")
    end

    it "users cannot update other users' collections" do
      collection = create(:ingredient_collection, user: user1, name: "Original")

      sign_in(user2)
      patch ingredient_collection_path(collection), params: { name: "Hacked" }

      expect(response).to have_http_status(:not_found)
      expect(collection.reload.name).to eq("Original")
    end

    it "users cannot delete other users' collections" do
      collection = create(:ingredient_collection, user: user1)

      sign_in(user2)
      delete ingredient_collection_path(collection)

      expect(response).to have_http_status(:not_found)
      expect(IngredientCollection.exists?(collection.id)).to be true
    end
  end
end
