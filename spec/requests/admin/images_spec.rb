require 'rails_helper'

RSpec.describe "Admin::Images", type: :request do
  let(:image_moderator) { create(:user, :image_moderator) }
  let(:admin)           { create(:user, :admin) }
  let(:regular_user)    { create(:user) }

  def create_forum_image(traits: [ :with_image ], **attrs)
    create(:forum_image, *traits, user: create(:user), **attrs)
  end

  def attach_avatar(user)
    file = Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'),
      'image/jpeg'
    )
    user.avatar.attach(file)
    user
  end

  describe "GET /admin/images (forum tab)" do
    before { sign_in(image_moderator) }

    it "returns http success" do
      get admin_images_path
      expect(response).to have_http_status(:success)
    end

    it "lists forum images" do
      uploader = create(:user)
      _fi = create_forum_image(user: uploader)
      get admin_images_path
      expect(response.body).to include(uploader.username)
    end

    it "shows orphan count badge when orphaned images exist" do
      create_forum_image(traits: [ :with_image, :orphaned ])
      get admin_images_path
      expect(response.body).to include("verwaist")
    end

    context "with orphan filter" do
      it "shows only orphaned images" do
        orphaned_user = create(:user)
        active_user   = create(:user)
        create_forum_image(traits: [ :with_image, :orphaned ], user: orphaned_user)
        create_forum_image(user: active_user)

        get admin_images_path, params: { filter: "orphan" }

        expect(response.body).to include(orphaned_user.username)
        expect(response.body).not_to include(active_user.username)
      end

      it "shows countdown to deletion" do
        create_forum_image(traits: [ :with_image, :orphaned ])
        get admin_images_path, params: { filter: "orphan" }
        expect(response.body).to include("Tagen")
      end
    end

    it "handles images from deleted users without crashing" do
      fi = create_forum_image
      fi.update_column(:user_id, nil)
      get admin_images_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("gelöschter Benutzer")
    end
  end

  describe "GET /admin/images?tab=avatar" do
    before { sign_in(image_moderator) }

    it "returns http success" do
      get admin_images_path(tab: "avatar")
      expect(response).to have_http_status(:success)
    end

    it "lists users with avatars" do
      user = attach_avatar(create(:user))
      get admin_images_path(tab: "avatar")
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /admin/images?tab=recipe" do
    before { sign_in(image_moderator) }

    it "redirects to admin recipe images" do
      get admin_images_path(tab: "recipe")
      expect(response).to redirect_to(admin_recipe_images_path)
    end
  end

  describe "access control" do
    it "redirects regular users to root" do
      sign_in(regular_user)
      get admin_images_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Zugriff verweigert.")
    end

    it "redirects unauthenticated requests to login" do
      get admin_images_path
      expect(response).to redirect_to(new_session_path)
    end

    it "allows admin access" do
      sign_in(admin)
      get admin_images_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /admin/images/:id" do
    before { sign_in(image_moderator) }

    it "destroys the forum image immediately" do
      fi = create_forum_image
      expect {
        delete admin_image_path(fi)
      }.to change(ForumImage, :count).by(-1)
    end

    it "redirects to forum tab with notice" do
      fi = create_forum_image
      delete admin_image_path(fi)
      expect(response).to redirect_to(admin_images_path(tab: "forum", filter: nil))
      expect(flash[:notice]).to eq("Bild gelöscht.")
    end

    it "refuses regular users" do
      fi = create_forum_image
      sign_in(regular_user)
      delete admin_image_path(fi)
      expect(response).to redirect_to(root_path)
      expect(ForumImage.exists?(fi.id)).to be true
    end
  end

  describe "POST /admin/images/:id/restore" do
    before { sign_in(image_moderator) }

    it "clears orphaned_at on the forum image" do
      fi = create_forum_image(traits: [ :with_image, :orphaned ])
      post restore_admin_image_path(fi)
      expect(fi.reload.orphaned_at).to be_nil
    end

    it "redirects to orphan filter with notice" do
      fi = create_forum_image(traits: [ :with_image, :orphaned ])
      post restore_admin_image_path(fi)
      expect(response).to redirect_to(admin_images_path(tab: "forum", filter: "orphan"))
      expect(flash[:notice]).to eq("Bild wiederhergestellt.")
    end

    it "refuses regular users" do
      fi = create_forum_image(traits: [ :with_image, :orphaned ])
      sign_in(regular_user)
      post restore_admin_image_path(fi)
      expect(fi.reload.orphaned_at).to be_present
    end
  end

  describe "DELETE /admin/images/avatar/:id" do
    before { sign_in(image_moderator) }

    it "purges the user avatar" do
      user = attach_avatar(create(:user))
      expect(user.avatar).to be_attached

      delete destroy_avatar_admin_images_path(user)

      expect(user.reload.avatar).not_to be_attached
    end

    it "redirects to avatar tab with notice" do
      user = attach_avatar(create(:user))
      delete destroy_avatar_admin_images_path(user)
      expect(response).to redirect_to(admin_images_path(tab: "avatar"))
      expect(flash[:notice]).to include(user.username)
    end

    it "refuses regular users" do
      user = attach_avatar(create(:user))
      sign_in(regular_user)
      delete destroy_avatar_admin_images_path(user)
      expect(response).to redirect_to(root_path)
      expect(user.reload.avatar).to be_attached
    end
  end
end
