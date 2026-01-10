require 'rails_helper'

RSpec.describe "RecipeImages", type: :request do
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

    it "paginates recipe images when there are more than 50" do
      # Create 51 approved images to trigger pagination
      51.times do |i|
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

      # First page should show 50 items
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
