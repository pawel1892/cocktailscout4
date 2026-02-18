require 'rails_helper'

RSpec.describe "RecipeImages", type: :request do
  let(:image_file) { fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg") }

  describe "GET /rezepte/:id/bilder" do
    let(:user)   { create(:user) }
    let(:recipe) { create(:recipe, title: "Tropical Storm", user: user) }

    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get bilder_recipe_path(recipe)
        expect(response).to have_http_status(:success)
      end

      it "displays the recipe title for context" do
        get bilder_recipe_path(recipe)
        expect(response.body).to include("Tropical Storm")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get bilder_recipe_path(recipe)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /rezepte/:id/bilder" do
    let(:user)   { create(:user) }
    let(:recipe) { create(:recipe, user: user) }

    context "when authenticated" do
      before { sign_in user }

      it "creates a recipe image and returns success JSON" do
        expect {
          post bilder_recipe_path(recipe), params: { image: image_file }
        }.to change(RecipeImage, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["message"]).to be_present
      end

      it "saves the image as pending (approved_at is nil)" do
        post bilder_recipe_path(recipe), params: { image: image_file }
        expect(RecipeImage.last.approved_at).to be_nil
      end

      it "associates the image with the uploading user" do
        post bilder_recipe_path(recipe), params: { image: image_file }
        expect(RecipeImage.last.user).to eq(user)
      end

      it "associates the image with the correct recipe" do
        post bilder_recipe_path(recipe), params: { image: image_file }
        expect(RecipeImage.last.recipe).to eq(recipe)
      end

      context "with an invalid content type" do
        let(:bad_file) { fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_document.txt"), "text/plain") }

        it "returns 422 with error JSON" do
          post bilder_recipe_path(recipe), params: { image: bad_file }
          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["errors"]).to be_present
        end

        it "does not create a record" do
          expect {
            post bilder_recipe_path(recipe), params: { image: bad_file }
          }.not_to change(RecipeImage, :count)
        end
      end

      it "the uploaded image is not approved and is excluded from the gallery" do
        post bilder_recipe_path(recipe), params: { image: image_file }
        expect(RecipeImage.last.approved_at).to be_nil
        expect(RecipeImage.approved).not_to include(RecipeImage.last)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post bilder_recipe_path(recipe), params: { image: image_file }
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a record" do
        expect {
          post bilder_recipe_path(recipe), params: { image: image_file }
        }.not_to change(RecipeImage, :count)
      end
    end
  end

  describe "GET /cocktailgalerie" do
    let(:user) { create(:user, username: "cocktail_master") }
    let(:approver) { create(:user) }
    let(:recipe) { create(:recipe, title: "Mojito", user: user) }

    it "displays approved recipe images" do
      approved_image = RecipeImage.new(
        recipe: recipe,
        user: user,
        approved_at: Time.current,
        approved_by: approver
      )
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      approved_image.image.attach(file)
      approved_image.save!

      get recipe_images_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Cocktailgalerie")
      expect(response.body).to include("Mojito")
      expect(response.body).to include("cocktail_master")
    end

    it "does not display non-approved recipe images" do
      pending_image = RecipeImage.new(
        recipe: recipe,
        user: user,
        approved_at: nil
      )
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      pending_image.image.attach(file)
      pending_image.save!

      get recipe_images_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Mojito")
      expect(response.body).not_to include("cocktail_master")
    end

    it "displays the correct recipe name and username for each image" do
      user1 = create(:user, username: "john_doe")
      user2 = create(:user, username: "jane_smith")
      recipe1 = create(:recipe, title: "Margarita", user: user1)
      recipe2 = create(:recipe, title: "Daiquiri", user: user2)

      image1 = RecipeImage.new(recipe: recipe1, user: user1, approved_at: Time.current, approved_by: approver)
      image2 = RecipeImage.new(recipe: recipe2, user: user2, approved_at: Time.current, approved_by: approver)

      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      image1.image.attach(file)
      image1.save!
      image2.image.attach(file)
      image2.save!

      get recipe_images_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Margarita")
      expect(response.body).to include("john_doe")
      expect(response.body).to include("Daiquiri")
      expect(response.body).to include("jane_smith")
    end

    it "paginates recipe images when there are more than 60" do
      # Create 61 approved images to trigger pagination
      61.times do |i|
        recipe_for_image = create(:recipe, title: "Cocktail #{i}", user: user)
        image = RecipeImage.new(
          recipe: recipe_for_image,
          user: user,
          approved_at: Time.current,
          approved_by: approver
        )
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        image.image.attach(file)
        image.save!
      end

      # First page should show 60 items
      get recipe_images_path

      expect(response).to have_http_status(:success)
      # Check for pagination controls/links
      expect(response.body).to match(/page=2|nav|pagination/)

      # Second page should show 1 item
      get recipe_images_path(page: 2)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Cocktail")
    end

    it "shows only approved images when mixed with pending images" do
      approved_recipe = create(:recipe, title: "Approved Cocktail", user: user)
      pending_recipe = create(:recipe, title: "Pending Cocktail", user: user)

      approved_image = RecipeImage.new(
        recipe: approved_recipe,
        user: user,
        approved_at: Time.current,
        approved_by: approver
      )
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      approved_image.image.attach(file)
      approved_image.save!

      pending_image = RecipeImage.new(
        recipe: pending_recipe,
        user: user,
        approved_at: nil
      )
      pending_image.image.attach(file)
      pending_image.save!

      get recipe_images_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Approved Cocktail")
      expect(response.body).not_to include("Pending Cocktail")
    end
  end
end
