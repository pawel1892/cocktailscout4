require "rails_helper"

RSpec.describe "Soft-deleted recipe image visibility", type: :request do
  let(:moderator) { create(:user) }
  let(:uploader)  { create(:user) }
  let(:recipe)    { create(:recipe, title: "Mojito", user: uploader) }

  def make_approved_image(recipe:)
    ri = RecipeImage.new(recipe: recipe, user: uploader, state: "approved",
                         moderated_by: moderator, moderated_at: Time.current)
    ri.image.attach(fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.jpg"), "image/jpeg"))
    ri.save!
    ri
  end

  describe "RecipeImage scopes" do
    it "approved scope includes non-deleted approved images" do
      image = make_approved_image(recipe: recipe)
      expect(RecipeImage.approved).to include(image)
    end

    it "approved scope includes soft-deleted images (state is still approved)" do
      image = make_approved_image(recipe: recipe)
      image.soft_delete!
      expect(RecipeImage.approved).to include(image)
    end

    it "approved.not_soft_deleted excludes soft-deleted images" do
      image = make_approved_image(recipe: recipe)
      image.soft_delete!
      expect(RecipeImage.approved.not_soft_deleted).not_to include(image)
    end
  end

  describe "Recipe#approved_recipe_images" do
    it "includes approved images that are not soft-deleted" do
      image = make_approved_image(recipe: recipe)
      expect(recipe.approved_recipe_images).to include(image)
    end

    it "excludes soft-deleted images" do
      image = make_approved_image(recipe: recipe)
      image.soft_delete!
      expect(recipe.reload.approved_recipe_images).not_to include(image)
    end
  end

  describe "GET /cocktailgalerie (public gallery)" do
    it "does not show soft-deleted images" do
      image = make_approved_image(recipe: recipe)
      image.soft_delete!

      get recipe_images_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Mojito")
    end

    it "still shows non-deleted approved images" do
      make_approved_image(recipe: recipe)

      get recipe_images_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mojito")
    end
  end

  describe "GET /rezepte/:slug (recipe show)" do
    it "does not include soft-deleted images in the image viewer" do
      image = make_approved_image(recipe: recipe)
      image.soft_delete!

      get recipe_path(recipe)

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(rails_blob_path(image.image, only_path: true))
    end

    it "includes non-deleted approved images in the image viewer" do
      image = make_approved_image(recipe: recipe)

      get recipe_path(recipe)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(image.id.to_s)
    end
  end

  describe "GET /rezepte (recipe index)" do
    it "does not raise errors when a recipe has only soft-deleted images" do
      image = make_approved_image(recipe: recipe)
      image.soft_delete!

      get recipes_path

      expect(response).to have_http_status(:success)
    end
  end
end
