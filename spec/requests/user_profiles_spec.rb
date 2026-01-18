require 'rails_helper'

RSpec.describe "User Profiles API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /user_profiles/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns own profile data with all fields" do
        user.update!(
          prename: "John",
          gender: "m",
          location: "Berlin",
          homepage: "https://example.com",
          title: "Developer",
          sign_in_count: 5
        )

        get user_profile_path(user), as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["id"]).to eq(user.id)
        expect(json["username"]).to eq(user.username)
        expect(json["prename"]).to eq("John")
        expect(json["gender"]).to eq("m")
        expect(json["location"]).to eq("Berlin")
        expect(json["homepage"]).to eq("https://example.com")
        expect(json["title"]).to eq("Developer")
        expect(json["rank"]).to eq(user.rank)
        expect(json["points"]).to eq(user.points)
        expect(json["sign_in_count"]).to eq(5)
        expect(json["created_at"]).to be_present
      end

      it "returns other user's profile data" do
        other_user.update!(prename: "Jane", gender: "w")

        get user_profile_path(other_user), as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["id"]).to eq(other_user.id)
        expect(json["username"]).to eq(other_user.username)
        expect(json["prename"]).to eq("Jane")
        expect(json["gender"]).to eq("w")
      end

      it "returns statistics counts" do
        # Create some test data for user
        recipe = create(:recipe, user: user)
        create(:recipe_image, :with_image, :approved, user: user)
        create(:recipe_comment, user: user)
        create(:rating, user: user, rateable: recipe, rateable_type: "Recipe")
        create(:forum_post, user: user)

        get user_profile_path(user), as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["recipes_count"]).to eq(1)
        expect(json["recipe_images_count"]).to eq(1)
        expect(json["recipe_comments_count"]).to eq(1)
        expect(json["ratings_count"]).to eq(1)
        expect(json["forum_posts_count"]).to eq(1)
      end

      it "returns zero for statistics when user has no activity" do
        get user_profile_path(user), as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["recipes_count"]).to eq(0)
        expect(json["recipe_images_count"]).to eq(0)
        expect(json["recipe_comments_count"]).to eq(0)
        expect(json["ratings_count"]).to eq(0)
        expect(json["forum_posts_count"]).to eq(0)
      end

      it "returns nil for optional profile fields when not set" do
        get user_profile_path(user), as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["prename"]).to be_nil
        expect(json["gender"]).to be_nil
        expect(json["location"]).to be_nil
        expect(json["homepage"]).to be_nil
        expect(json["title"]).to be_nil
      end

      it "returns 404 for non-existent user" do
        get user_profile_path(id: 99999), as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "allows viewing user profiles without authentication" do
        get user_profile_path(user), as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["username"]).to eq(user.username)
      end
    end
  end

  describe "PATCH /user_profiles/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "successfully updates own profile" do
        patch user_profile_path(user), params: {
          user: {
            prename: "Updated Name",
            gender: "m",
            location: "Munich",
            homepage: "https://newsite.com",
            title: "Senior Developer"
          }
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["prename"]).to eq("Updated Name")
        expect(json["gender"]).to eq("m")
        expect(json["location"]).to eq("Munich")
        expect(json["homepage"]).to eq("https://newsite.com")
        expect(json["title"]).to eq("Senior Developer")

        user.reload
        expect(user.prename).to eq("Updated Name")
        expect(user.gender).to eq("m")
        expect(user.location).to eq("Munich")
        expect(user.homepage).to eq("https://newsite.com")
        expect(user.title).to eq("Senior Developer")
      end

      it "updates individual profile fields" do
        patch user_profile_path(user), params: {
          user: { prename: "Just Name" }
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["prename"]).to eq("Just Name")
        expect(user.reload.prename).to eq("Just Name")
      end

      it "allows clearing profile fields" do
        user.update!(prename: "John", gender: "m")

        patch user_profile_path(user), params: {
          user: { prename: "", gender: "" }
        }, as: :json

        expect(response).to have_http_status(:success)
        user.reload
        expect(user.prename).to eq("")
        expect(user.gender).to eq("")
      end

      it "returns updated profile data after successful update" do
        patch user_profile_path(user), params: {
          user: { prename: "New Name" }
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        # Should return full profile structure
        expect(json).to have_key("id")
        expect(json).to have_key("username")
        expect(json).to have_key("prename")
        expect(json).to have_key("rank")
        expect(json).to have_key("points")
        expect(json).to have_key("recipes_count")
      end

      it "returns 403 when trying to update another user's profile" do
        patch user_profile_path(other_user), params: {
          user: { prename: "Hacked" }
        }, as: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Unauthorized")

        other_user.reload
        expect(other_user.prename).not_to eq("Hacked")
      end

      it "does not allow updating protected fields" do
        original_username = user.username
        original_email = user.email_address

        patch user_profile_path(user), params: {
          user: {
            prename: "John",
            username: "hacker",
            email_address: "hacker@evil.com",
            admin: true
          }
        }, as: :json

        expect(response).to have_http_status(:success)
        user.reload

        # Allowed field should be updated
        expect(user.prename).to eq("John")

        # Protected fields should not change
        expect(user.username).to eq(original_username)
        expect(user.email_address).to eq(original_email)
        expect(user.admin?).to be false
      end

      it "returns validation errors for invalid data" do
        # Assuming there might be validations in the future
        # For now this tests the error handling structure
        allow_any_instance_of(User).to receive(:update).and_return(false)
        allow_any_instance_of(User).to receive(:errors).and_return(
          double(full_messages: [ "Validation error" ])
        )

        patch user_profile_path(user), params: {
          user: { prename: "Test" }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to eq([ "Validation error" ])
      end
    end

    context "when not authenticated" do
      it "redirects to login when trying to update profile" do
        patch user_profile_path(user), params: {
          user: { prename: "Hacker" }
        }, as: :json

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end

      it "does not update the user" do
        original_prename = user.prename

        patch user_profile_path(user), params: {
          user: { prename: "Hacker" }
        }, as: :json

        expect(user.reload.prename).to eq(original_prename)
      end
    end
  end

  describe "profile isolation and security" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      user1.update!(prename: "User1", location: "Berlin")
      user2.update!(prename: "User2", location: "Munich")
    end

    it "users can view but not edit other users' profiles" do
      sign_in(user1)

      # Can view other user's profile
      get user_profile_path(user2), as: :json
      expect(response).to have_http_status(:success)

      # Cannot edit other user's profile
      patch user_profile_path(user2), params: {
        user: { prename: "Hacked" }
      }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(user2.reload.prename).to eq("User2")
    end

    it "users can only update their own profile" do
      sign_in(user1)

      patch user_profile_path(user1), params: {
        user: { prename: "Updated" }
      }, as: :json

      expect(response).to have_http_status(:success)
      expect(user1.reload.prename).to eq("Updated")
    end
  end
end
