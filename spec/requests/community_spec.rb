require 'rails_helper'

RSpec.describe "Community", type: :request do
  describe "GET /community" do
    let!(:online_user)  { create(:user, last_active_at: 2.minutes.ago) }
    let!(:offline_user) { create(:user, :unconfirmed, last_active_at: 10.minutes.ago) }

    it "returns http success" do
      get community_path
      expect(response).to have_http_status(:success)
    end

    it "displays users active within 5 minutes" do
      get community_path
      expect(response.body).to include(online_user.username)
    end

    it "does not display users inactive for more than 5 minutes" do
      get community_path
      expect(response.body).not_to include(offline_user.username)
    end

    it "includes the activity stream script tag" do
      get community_path
      expect(response.body).to include("window.activityStream")
    end

    it "mounts the activity-stream component" do
      get community_path
      expect(response.body).to include("activity-stream")
    end

    it "does not include the old forum threads section" do
      get community_path
      expect(response.body).not_to include("Zuletzt aktive Themen")
    end

    it "does not include the old recipe comments section" do
      get community_path
      expect(response.body).not_to include("Neuste Kommentare")
    end

    it "populates activity stream with recent events" do
      recipe = create(:recipe)
      get community_path
      expect(response.body).to include(recipe.slug)
    end
  end

  describe "GET /community.json" do
    let!(:online_user)  { create(:user, last_active_at: 2.minutes.ago) }
    let!(:offline_user) { create(:user, :unconfirmed, last_active_at: 10.minutes.ago) }

    it "returns online users" do
      get community_path, as: :json

      expect(response).to have_http_status(:success)
      ids = response.parsed_body["online_users"].pluck("id")
      expect(ids).to include(online_user.id)
      expect(ids).not_to include(offline_user.id)
    end

    it "includes id, username and rank for each online user" do
      get community_path, as: :json

      user_json = response.parsed_body["online_users"].first
      expect(user_json.keys).to match_array(%w[id username rank])
    end

    it "includes activity_stream in the response" do
      get community_path, as: :json

      expect(response.parsed_body).to have_key("activity_stream")
    end

    it "returns activity_stream as an array" do
      get community_path, as: :json

      expect(response.parsed_body["activity_stream"]).to be_an(Array)
    end
  end
end
