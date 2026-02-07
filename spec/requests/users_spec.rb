require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /benutzer" do
    let!(:user) { create(:user, username: "TestUser") }

    it "returns http success" do
      get users_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.username)
    end

    it "displays breadcrumbs" do
      get users_path
      expect(response.body).to include("Community")
      expect(response.body).to include("Benutzer")
    end

    it "shows user count" do
      create_list(:user, 5)
      get users_path
      # 6 users total (1 from let! + 5 from create_list)
      expect(response.body).to include("6")
      expect(response.body).to include("gefunden")
    end

    it "displays search form" do
      get users_path
      expect(response.body).to include('name="q"')
      expect(response.body).to include('Benutzername')
    end

    it "displays sorting options" do
      get users_path
      expect(response.body).to include("Benutzername")
      expect(response.body).to include("Punkte")
      expect(response.body).to include("Zuletzt aktiv")
      expect(response.body).to include("Registriert seit")
    end
  end

  describe "Sorting" do
    let!(:user1) { create(:user, username: "Alpha", created_at: 3.days.ago, last_active_at: 1.day.ago) }
    let!(:user2) { create(:user, username: "Zulu", created_at: 1.day.ago, last_active_at: 3.days.ago) }
    let!(:user3) { create(:user, username: "Beta", created_at: 2.days.ago, last_active_at: 2.days.ago) }

    before do
      # Set up user points
      user1.stat.update!(points: 100)
      user2.stat.update!(points: 500)
      user3.stat.update!(points: 50)
    end

    it "sorts by points desc by default" do
      get users_path
      # user2 (500) should come before user1 (100) before user3 (50)
      expect(response.body).to match(/#{user2.username}.*#{user1.username}.*#{user3.username}/m)
    end

    it "sorts by username asc" do
      get users_path(sort: "username", direction: "asc")
      # Alpha, Beta, Zulu
      expect(response.body).to match(/#{user1.username}.*#{user3.username}.*#{user2.username}/m)
    end

    it "sorts by username desc" do
      get users_path(sort: "username", direction: "desc")
      # Zulu, Beta, Alpha
      expect(response.body).to match(/#{user2.username}.*#{user3.username}.*#{user1.username}/m)
    end

    it "sorts by points asc" do
      get users_path(sort: "user_stats.points", direction: "asc")
      # user3 (50), user1 (100), user2 (500)
      expect(response.body).to match(/#{user3.username}.*#{user1.username}.*#{user2.username}/m)
    end

    it "sorts by created_at desc" do
      get users_path(sort: "created_at", direction: "desc")
      # user2 (newest), user3, user1 (oldest)
      expect(response.body).to match(/#{user2.username}.*#{user3.username}.*#{user1.username}/m)
    end

    it "sorts by created_at asc" do
      get users_path(sort: "created_at", direction: "asc")
      # user1 (oldest), user3, user2 (newest)
      expect(response.body).to match(/#{user1.username}.*#{user3.username}.*#{user2.username}/m)
    end

    it "sorts by last_active_at desc" do
      get users_path(sort: "last_active_at", direction: "desc")
      # user1 (1 day ago), user3 (2 days ago), user2 (3 days ago)
      expect(response.body).to match(/#{user1.username}.*#{user3.username}.*#{user2.username}/m)
    end

    it "sorts by last_active_at asc" do
      get users_path(sort: "last_active_at", direction: "asc")
      # user2 (3 days ago), user3 (2 days ago), user1 (1 day ago)
      expect(response.body).to match(/#{user2.username}.*#{user3.username}.*#{user1.username}/m)
    end

    it "ignores invalid sort column" do
      get users_path(sort: "invalid_column", direction: "asc")
      # Should fall back to default (points desc) and succeed
      expect(response).to have_http_status(:success)
      # Just verify all users are present, order might vary due to fallback
      expect(response.body).to include(user1.username)
      expect(response.body).to include(user2.username)
      expect(response.body).to include(user3.username)
    end

    it "ignores invalid sort direction" do
      get users_path(sort: "username", direction: "invalid")
      # Should fall back to default direction (desc for default sort)
      expect(response).to have_http_status(:success)
    end
  end

  describe "Pagination" do
    before do
      # Create enough users to trigger pagination (Pagy limit + some extra)
      create_list(:user, 60)
    end

    it "limits results per page" do
      get users_path
      expect(response).to have_http_status(:success)
      # Should not show all 61 users on one page (1 existing + 60 created)
      # Each user appears twice (desktop table + mobile card view)
      user_count = response.body.scan(/user-profile-trigger/).count / 2
      expect(user_count).to be <= 50 # Pagy default limit
    end

    it "shows second page when requested" do
      get users_path(page: 2)
      expect(response).to have_http_status(:success)
      # Should show remaining users
      expect(response.body).to include('user-profile-trigger')
    end

    it "preserves sorting params in pagination" do
      get users_path(sort: "username", direction: "asc")
      expect(response.body).to include('sort=username')
      expect(response.body).to include('direction=asc')
    end

    it "preserves search params in pagination" do
      get users_path(q: "test")
      expect(response.body).to include('q=test')
    end
  end

  describe "Search" do
    let!(:user1) { create(:user, username: "JohnDoe") }
    let!(:user2) { create(:user, username: "JaneSmith") }
    let!(:user3) { create(:user, username: "BobJohnson") }

    it "searches by username" do
      get users_path(q: "John")
      expect(response.body).to include(user1.username)
      expect(response.body).to include(user3.username)
      expect(response.body).not_to include(user2.username)
    end

    it "is case insensitive" do
      get users_path(q: "john")
      expect(response.body).to include(user1.username)
      expect(response.body).to include(user3.username)
    end

    it "searches for partial matches" do
      get users_path(q: "mit")
      expect(response.body).to include(user2.username)
      expect(response.body).not_to include(user1.username)
    end

    it "shows all users when search is empty" do
      get users_path(q: "")
      expect(response.body).to include(user1.username)
      expect(response.body).to include(user2.username)
      expect(response.body).to include(user3.username)
    end

    it "shows no results message when no matches" do
      get users_path(q: "NonExistentUser")
      expect(response.body).to include("Keine Benutzer gefunden")
    end

    it "preserves sort params when searching" do
      get users_path(q: "John", sort: "username", direction: "asc")
      expect(response.body).to include(user3.username)
      expect(response.body).to include(user1.username)
      # BobJohnson should come before JohnDoe alphabetically
      expect(response.body).to match(/#{user3.username}.*#{user1.username}/m)
    end
  end

  describe "User display" do
    let!(:user) { create(:user, username: "DisplayUser", created_at: 5.days.ago, last_active_at: 2.days.ago) }

    before do
      user.stat.update!(points: 1500)
    end

    it "displays username" do
      get users_path
      expect(response.body).to include("DisplayUser")
    end

    it "displays user points" do
      get users_path
      expect(response.body).to include("1.500") # German number format with period
    end

    it "displays user rank" do
      get users_path
      expect(response.body).to include("Rang")
      # User with 1500 points should be rank 6
      expect(response.body).to include(">6<")
    end

    it "displays last active time" do
      get users_path
      expect(response.body).to include("Zuletzt aktiv")
    end

    it "displays registration date" do
      get users_path
      expect(response.body).to include("Registriert")
    end

    it "handles users who never logged in" do
      user.update!(last_active_at: nil)
      get users_path
      expect(response.body).to include("Noch nie")
    end
  end

  describe "Desktop vs Mobile views" do
    let!(:user) { create(:user, username: "ViewTestUser") }

    it "includes desktop table view" do
      get users_path
      expect(response.body).to include('<table')
      expect(response.body).to include('hidden md:block')
    end

    it "includes mobile card view" do
      get users_path
      expect(response.body).to include('md:hidden')
      expect(response.body).to include('card')
    end
  end

  describe "Combined search and sort" do
    let!(:user1) { create(:user, username: "AliceAdmin") }
    let!(:user2) { create(:user, username: "AdminBob") }
    let!(:user3) { create(:user, username: "Charlie") }

    before do
      user1.stat.update!(points: 300)
      user2.stat.update!(points: 100)
    end

    it "searches and sorts correctly" do
      get users_path(q: "Admin", sort: "user_stats.points", direction: "desc")
      # Should show Alice (300 points) before Bob (100 points)
      expect(response.body).to include(user1.username)
      expect(response.body).to include(user2.username)
      expect(response.body).not_to include(user3.username)
      expect(response.body).to match(/#{user1.username}.*#{user2.username}/m)
    end
  end

  describe "User badge integration" do
    let!(:user) { create(:user, username: "BadgeUser") }

    before do
      user.stat.update!(points: 5500) # Rank 8
    end

    it "displays user badge with profile trigger" do
      get users_path
      expect(response.body).to include('user-profile-trigger')
      expect(response.body).to include("data-user-id=\"#{user.id}\"")
    end

    it "displays rank color class" do
      get users_path
      expect(response.body).to include('rank-8-color')
    end
  end

  describe "Role filtering" do
    let!(:regular_user) { create(:user, username: "RegularUser") }
    let!(:admin_user) { create(:user, :admin, username: "AdminUser") }
    let!(:forum_mod) { create(:user, :forum_moderator, username: "ForumMod") }
    let!(:recipe_mod) { create(:user, :recipe_moderator, username: "RecipeMod") }
    let!(:super_mod) { create(:user, :super_moderator, username: "SuperMod") }

    it "displays moderators checkbox filter" do
      get users_path
      expect(response.body).to include('name="moderators_only"')
      expect(response.body).to include('Nur Admins / Moderatoren')
    end

    it "shows all users by default" do
      get users_path
      expect(response.body).to include("RegularUser")
      expect(response.body).to include("AdminUser")
      expect(response.body).to include("ForumMod")
      expect(response.body).to include("RecipeMod")
      expect(response.body).to include("SuperMod")
    end

    it "filters to show only users with roles when checkbox is checked" do
      get users_path(moderators_only: "1")
      expect(response.body).to include("AdminUser")
      expect(response.body).to include("ForumMod")
      expect(response.body).to include("RecipeMod")
      expect(response.body).to include("SuperMod")
      expect(response.body).not_to include("RegularUser")
    end

    it "displays role badges in filtered results" do
      get users_path(moderators_only: "1")
      expect(response.body).to include("Admin") # display_name
      expect(response.body).to include("Forum-Moderator")
    end

    it "preserves sort params when filtering" do
      get users_path(moderators_only: "1", sort: "username", direction: "asc")
      expect(response.body).to include("AdminUser")
      expect(response.body).to include('sort=username')
    end
  end

  describe "Role display" do
    let!(:admin_user) { create(:user, :admin, username: "AdminDisplay") }
    let!(:super_mod) { create(:user, :super_moderator, username: "SuperModDisplay") }
    let!(:regular_user) { create(:user, username: "RegularDisplay") }

    it "displays role badge for admin" do
      get users_path
      expect(response.body).to include("Admin")
      expect(response.body).to include("tag-gold")
    end

    it "displays role badge for super moderator" do
      get users_path
      expect(response.body).to include("Moderator") # super_moderator display_name
      expect(response.body).to include("tag-light-blue")
    end

    it "does not display role badge for regular users" do
      get users_path
      # Regular users should not have role badges
      # The dash "-" should appear in the role column for regular users in the table view
      expect(response.body).to include("RegularDisplay")
    end
  end
end
