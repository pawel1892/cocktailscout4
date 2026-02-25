require 'rails_helper'

RSpec.describe "Community", type: :request do
  describe "GET /community" do
    let!(:online_user) { create(:user, last_active_at: 2.minutes.ago) }
    let!(:offline_user) { create(:user, last_active_at: 10.minutes.ago) }
    let!(:forum_topic) { create(:forum_topic) }
    let!(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, updated_at: 1.hour.ago) }
    let!(:recent_forum_thread) { create(:forum_thread, forum_topic: forum_topic, updated_at: 5.minutes.ago) }
    let!(:recipe) { create(:recipe) }
    let!(:comment) { create(:recipe_comment, recipe: recipe, created_at: 10.minutes.ago, user: online_user) }

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

    it "displays recent forum threads" do
      get community_path
      expect(response.body).to include(recent_forum_thread.title)
    end

    it "displays recent recipe comments" do
      get community_path
      expect(response.body).to include(comment.recipe.title)
    end
  end

  describe "GET /community.json" do
    let!(:online_user) { create(:user, last_active_at: 2.minutes.ago) }
    let!(:offline_user) { create(:user, last_active_at: 10.minutes.ago) }

    it "returns online users as JSON" do
      get community_path, as: :json

      expect(response).to have_http_status(:success)
      json = response.parsed_body
      ids = json["online_users"].pluck("id")
      expect(ids).to include(online_user.id)
      expect(ids).not_to include(offline_user.id)
    end

    it "includes id, username and rank for each user" do
      get community_path, as: :json

      user_json = response.parsed_body["online_users"].first
      expect(user_json.keys).to match_array(%w[id username rank])
    end
  end
end
