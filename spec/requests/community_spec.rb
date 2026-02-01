require 'rails_helper'

RSpec.describe "Community", type: :request do
  describe "GET /community" do
    let!(:user) { create(:user, last_active_at: 10.minutes.ago) }
    let!(:inactive_user) { create(:user, last_active_at: 1.hour.ago) }
    let!(:forum_topic) { create(:forum_topic) }
    let!(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, updated_at: 1.hour.ago) }
    let!(:recent_forum_thread) { create(:forum_thread, forum_topic: forum_topic, updated_at: 5.minutes.ago) }
    let!(:recipe) { create(:recipe) }
    let!(:comment) { create(:recipe_comment, recipe: recipe, created_at: 10.minutes.ago, user: user) }

    it "returns http success" do
      get community_path
      expect(response).to have_http_status(:success)
    end

    it "displays online users" do
      get community_path
      expect(response.body).to include(user.username)
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
end
