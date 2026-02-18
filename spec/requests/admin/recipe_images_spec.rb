require 'rails_helper'

RSpec.describe "Admin::RecipeImages", type: :request do
  let(:admin)           { create(:user, :admin) }
  let(:image_moderator) { create(:user, :image_moderator) }
  let(:super_moderator) { create(:user, :super_moderator) }
  let(:regular_user)    { create(:user) }
  let(:uploader)        { create(:user) }
  let(:recipe)          { create(:recipe, user: uploader) }

  def create_recipe_image(state: "pending", moderator: nil)
    ri = RecipeImage.new(recipe: recipe, user: uploader, state: state)
    if moderator
      ri.moderated_by = moderator
      ri.moderated_at = 1.day.ago
    end
    file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
    ri.image.attach(file)
    ri.save!
    ri
  end

  let!(:pending_image)  { create_recipe_image(state: "pending") }
  let!(:approved_image) { create_recipe_image(state: "approved", moderator: admin) }
  let!(:rejected_image) { create_recipe_image(state: "rejected", moderator: admin) }

  describe "GET /admin/recipe_images" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "returns http success" do
        get admin_recipe_images_path
        expect(response).to have_http_status(:success)
      end

      it "shows all images by default" do
        get admin_recipe_images_path
        expect(response.body).to include(uploader.username)
      end

      it "filters by pending state" do
        get admin_recipe_images_path, params: { state: "pending" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Wartend")
      end

      it "filters by approved state" do
        get admin_recipe_images_path, params: { state: "approved" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Genehmigt")
      end

      it "filters by rejected state" do
        get admin_recipe_images_path, params: { state: "rejected" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Abgelehnt")
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "returns http success" do
        get admin_recipe_images_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as super_moderator" do
      before { sign_in(super_moderator) }

      it "returns http success" do
        get admin_recipe_images_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        get admin_recipe_images_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get admin_recipe_images_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/recipe_images/:id" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "returns http success for pending image" do
        get admin_recipe_image_path(pending_image)
        expect(response).to have_http_status(:success)
      end

      it "shows approve and reject buttons for pending image" do
        get admin_recipe_image_path(pending_image)
        expect(response.body).to include("Bild genehmigen")
        expect(response.body).to include("Bild ablehnen")
      end

      it "shows moderation info for approved image" do
        get admin_recipe_image_path(approved_image)
        expect(response.body).to include("Moderationsinformationen")
        expect(response.body).not_to include("Bild genehmigen")
      end

      it "shows moderation info for rejected image" do
        get admin_recipe_image_path(rejected_image)
        expect(response.body).to include("Moderationsinformationen")
        expect(response.body).not_to include("Bild genehmigen")
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        get admin_recipe_image_path(pending_image)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end
  end

  describe "POST /admin/recipe_images/:id/approve" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "approves the image" do
        post approve_admin_recipe_image_path(pending_image)
        pending_image.reload
        expect(pending_image.state).to eq("approved")
        expect(pending_image.moderated_by).to eq(image_moderator)
        expect(pending_image.moderated_at).to be_present
      end

      it "sends a private message to the uploader" do
        expect {
          post approve_admin_recipe_image_path(pending_image)
        }.to change { PrivateMessage.count }.by(1)

        msg = PrivateMessage.last
        expect(msg.receiver).to eq(uploader)
        expect(msg.sender).to eq(image_moderator)
        expect(msg.subject).to include("genehmigt")
        expect(msg.body).to include(recipe.title)
      end

      it "redirects to index with success notice" do
        post approve_admin_recipe_image_path(pending_image)
        expect(response).to redirect_to(admin_recipe_images_path)
        expect(flash[:notice]).to eq("Bild wurde genehmigt.")
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "can approve images" do
        post approve_admin_recipe_image_path(pending_image)
        pending_image.reload
        expect(pending_image.state).to eq("approved")
        expect(pending_image.moderated_by).to eq(admin)
      end
    end

    context "as super_moderator" do
      before { sign_in(super_moderator) }

      it "can approve images" do
        post approve_admin_recipe_image_path(pending_image)
        pending_image.reload
        expect(pending_image.state).to eq("approved")
        expect(pending_image.moderated_by).to eq(super_moderator)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        post approve_admin_recipe_image_path(pending_image)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "does not change the image state" do
        post approve_admin_recipe_image_path(pending_image)
        expect(pending_image.reload.state).to eq("pending")
      end
    end
  end

  describe "POST /admin/recipe_images/:id/reject" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "rejects the image with a reason" do
        post reject_admin_recipe_image_path(pending_image),
             params: { moderation_reason: "Unangemessener Inhalt" }
        pending_image.reload
        expect(pending_image.state).to eq("rejected")
        expect(pending_image.moderated_by).to eq(image_moderator)
        expect(pending_image.moderated_at).to be_present
        expect(pending_image.moderation_reason).to eq("Unangemessener Inhalt")
      end

      it "rejects the image without a reason" do
        post reject_admin_recipe_image_path(pending_image)
        pending_image.reload
        expect(pending_image.state).to eq("rejected")
        expect(pending_image.moderation_reason).to be_nil
      end

      it "sends a private message to the uploader with the reason" do
        expect {
          post reject_admin_recipe_image_path(pending_image),
               params: { moderation_reason: "Unangemessener Inhalt" }
        }.to change { PrivateMessage.count }.by(1)

        msg = PrivateMessage.last
        expect(msg.receiver).to eq(uploader)
        expect(msg.sender).to eq(image_moderator)
        expect(msg.body).to include("Unangemessener Inhalt")
        expect(msg.body).to include(recipe.title)
      end

      it "sends a private message without reason when none given" do
        expect {
          post reject_admin_recipe_image_path(pending_image)
        }.to change { PrivateMessage.count }.by(1)

        msg = PrivateMessage.last
        expect(msg.receiver).to eq(uploader)
        expect(msg.body).not_to include("Begründung:")
      end

      it "redirects to index with success notice" do
        post reject_admin_recipe_image_path(pending_image),
             params: { moderation_reason: "Unangemessener Inhalt" }
        expect(response).to redirect_to(admin_recipe_images_path)
        expect(flash[:notice]).to eq("Bild wurde abgelehnt.")
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "can reject images" do
        post reject_admin_recipe_image_path(pending_image),
             params: { moderation_reason: "Admin rejection" }
        pending_image.reload
        expect(pending_image.state).to eq("rejected")
        expect(pending_image.moderated_by).to eq(admin)
      end
    end

    context "as super_moderator" do
      before { sign_in(super_moderator) }

      it "can reject images" do
        post reject_admin_recipe_image_path(pending_image),
             params: { moderation_reason: "Super mod rejection" }
        pending_image.reload
        expect(pending_image.state).to eq("rejected")
        expect(pending_image.moderated_by).to eq(super_moderator)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        post reject_admin_recipe_image_path(pending_image),
             params: { moderation_reason: "Should not work" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "does not change the image state" do
        post reject_admin_recipe_image_path(pending_image),
             params: { moderation_reason: "Should not work" }
        expect(pending_image.reload.state).to eq("pending")
      end
    end
  end

  describe "GET /admin/recipe_images/count" do
    context "as image_moderator" do
      before { sign_in(image_moderator) }

      it "returns pending image count as JSON" do
        get count_admin_recipe_images_path
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)
      end

      it "does not count approved or rejected images" do
        get count_admin_recipe_images_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "returns pending image count" do
        get count_admin_recipe_images_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        get count_admin_recipe_images_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get count_admin_recipe_images_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
