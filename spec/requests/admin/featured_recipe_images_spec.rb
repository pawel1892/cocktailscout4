require 'rails_helper'

RSpec.describe "Admin::FeaturedRecipeImages", type: :request do
  let(:image_moderator) { create(:user, :image_moderator) }
  let(:regular_user)    { create(:user) }
  let(:uploader)        { create(:user) }
  let(:recipe)          { create(:recipe, user: uploader, is_public: true) }

  def create_approved_image(recipe: nil, featured_at: nil)
    target = recipe || self.recipe
    ri = RecipeImage.new(
      recipe: target, user: uploader,
      state: "approved", moderated_at: Time.current, moderated_by: image_moderator,
      featured_at: featured_at
    )
    file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
    ri.image.attach(file)
    ri.save!
    ri
  end

  describe "POST /admin/featured_recipe_images" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "features the image" do
        approved_image = create_approved_image
        post admin_featured_recipe_images_path, params: { recipe_image_id: approved_image.id }
        expect(approved_image.reload.featured_at).to be_present
      end

      it "redirects to the image show page with a notice" do
        approved_image = create_approved_image
        post admin_featured_recipe_images_path, params: { recipe_image_id: approved_image.id }
        expect(response).to redirect_to(admin_recipe_image_path(approved_image))
        expect(flash[:notice]).to eq("Bild wurde als Featured gesetzt.")
      end

      it "clears featured_at on the previously featured image" do
        recipe2            = create(:recipe, user: uploader, is_public: true)
        previously_featured = create_approved_image(recipe: recipe2, featured_at: 1.hour.ago)
        approved_image     = create_approved_image
        post admin_featured_recipe_images_path, params: { recipe_image_id: approved_image.id }
        expect(previously_featured.reload.featured_at).to be_nil
      end

      it "redirects to index with alert when feature! raises" do
        pending_image = RecipeImage.new(recipe: recipe, user: uploader, state: "pending")
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        pending_image.image.attach(file)
        pending_image.save!
        post admin_featured_recipe_images_path, params: { recipe_image_id: pending_image.id }
        expect(response).to redirect_to(admin_recipe_images_path)
        expect(flash[:alert]).to start_with("Fehler:")
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with alert" do
        approved_image = create_approved_image
        post admin_featured_recipe_images_path, params: { recipe_image_id: approved_image.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "does not feature the image" do
        approved_image = create_approved_image
        post admin_featured_recipe_images_path, params: { recipe_image_id: approved_image.id }
        expect(approved_image.reload.featured_at).to be_nil
      end
    end

    context "when unauthenticated" do
      it "redirects to the login page" do
        approved_image = create_approved_image
        post admin_featured_recipe_images_path, params: { recipe_image_id: approved_image.id }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /admin/featured_recipe_images/:id" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "clears featured_at on the image" do
        featured_image = create_approved_image(featured_at: Time.current)
        delete admin_featured_recipe_image_path(featured_image)
        expect(featured_image.reload.featured_at).to be_nil
      end

      it "redirects to the image show page with a notice" do
        featured_image = create_approved_image(featured_at: Time.current)
        delete admin_featured_recipe_image_path(featured_image)
        expect(response).to redirect_to(admin_recipe_image_path(featured_image))
        expect(flash[:notice]).to eq("Bild wurde als Featured entfernt.")
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with alert" do
        featured_image = create_approved_image(featured_at: Time.current)
        delete admin_featured_recipe_image_path(featured_image)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "does not unfeature the image" do
        featured_image = create_approved_image(featured_at: Time.current)
        delete admin_featured_recipe_image_path(featured_image)
        expect(featured_image.reload.featured_at).to be_present
      end
    end

    context "when unauthenticated" do
      it "redirects to the login page" do
        featured_image = create_approved_image(featured_at: Time.current)
        delete admin_featured_recipe_image_path(featured_image)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
