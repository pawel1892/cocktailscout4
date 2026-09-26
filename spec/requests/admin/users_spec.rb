require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:super_moderator) { create(:user, :super_moderator) }
  let(:recipe_moderator) { create(:user, :recipe_moderator) }
  let(:regular_user) { create(:user) }

  describe "Authorization" do
    it "allows admins" do
      sign_in admin
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "allows super moderators" do
      sign_in super_moderator
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "denies other moderators" do
      sign_in recipe_moderator
      get admin_users_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Zugriff verweigert.")
    end

    it "denies regular users" do
      sign_in regular_user
      post ban_admin_user_path(create(:user)), params: { ban_reason: "Spam" }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "Admin navigation" do
    it "shows the users link to admins" do
      sign_in admin
      get admin_units_path
      expect(response.body).to include(%(href="#{admin_users_path}"))
    end

    it "hides the users link from other moderators" do
      sign_in recipe_moderator
      get admin_units_path
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(%(href="#{admin_users_path}"))
    end
  end

  describe "GET /admin/users" do
    before { sign_in admin }

    it "searches by username" do
      create(:user, username: "findme")
      create(:user, username: "other")

      get admin_users_path(q: "findme")

      expect(response.body).to include("findme")
      expect(response.body).not_to include("other")
    end

    it "filters banned users" do
      create(:user, :banned, username: "badguy")
      create(:user, username: "goodguy")

      get admin_users_path(status: "banned")

      expect(response.body).to include("badguy")
      expect(response.body).not_to include("goodguy")
    end
  end

  describe "GET /admin/users/:id" do
    before { sign_in admin }

    it "shows the ban form for a regular user" do
      get admin_user_path(regular_user)
      expect(response.body).to include("Sperren")
    end

    it "shows ban details for a banned user" do
      banned = create(:user, :banned, ban_reason: "Beleidigungen")
      get admin_user_path(banned)
      expect(response.body).to include("Beleidigungen")
      expect(response.body).to include("Entsperren")
    end
  end

  describe "POST /admin/users/:id/ban" do
    before { sign_in admin }

    it "bans the user permanently" do
      post ban_admin_user_path(regular_user), params: { ban_reason: "Spam" }

      regular_user.reload
      expect(regular_user.banned?).to be true
      expect(regular_user.banned_until).to be_nil
      expect(regular_user.banned_by).to eq(admin)
      expect(response).to redirect_to(admin_user_path(regular_user))
    end

    it "bans the user until the end of the given day" do
      date = 7.days.from_now.to_date
      post ban_admin_user_path(regular_user), params: { ban_reason: "Spam", banned_until: date.iso8601 }

      expect(regular_user.reload.banned_until).to be_within(1.second).of(date.end_of_day)
    end

    it "falls back to a permanent ban for an invalid date" do
      post ban_admin_user_path(regular_user), params: { ban_reason: "Spam", banned_until: "kein-datum" }

      regular_user.reload
      expect(regular_user.banned?).to be true
      expect(regular_user.banned_until).to be_nil
    end

    it "requires a reason" do
      post ban_admin_user_path(regular_user), params: { ban_reason: "" }

      expect(regular_user.reload.banned?).to be false
      expect(flash[:alert]).to eq("Bitte gib einen Grund für die Sperre an.")
    end

    it "does not allow banning yourself" do
      post ban_admin_user_path(admin), params: { ban_reason: "Test" }

      expect(admin.reload.banned?).to be false
    end

    it "does not allow banning admins or super moderators" do
      post ban_admin_user_path(super_moderator), params: { ban_reason: "Test" }

      expect(super_moderator.reload.banned?).to be false
    end
  end

  describe "POST /admin/users/:id/unban" do
    before { sign_in super_moderator }

    it "lifts the ban" do
      banned = create(:user, :banned)

      post unban_admin_user_path(banned)

      expect(banned.reload.banned?).to be false
      expect(response).to redirect_to(admin_user_path(banned))
    end
  end
end
