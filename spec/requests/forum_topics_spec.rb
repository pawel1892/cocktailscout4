require 'rails_helper'

RSpec.describe "ForumTopics", type: :request do
  describe "GET /cocktailforum" do
    let!(:topic1) { create(:forum_topic, name: "General Discussion", position: 1) }
    let!(:topic2) { create(:forum_topic, name: "Cocktail Recipes", position: 2) }

    it "returns http success" do
      get forum_topics_path
      expect(response).to have_http_status(:success)
    end

    it "displays all forum topics" do
      get forum_topics_path
      expect(response.body).to include("General Discussion")
      expect(response.body).to include("Cocktail Recipes")
    end

    it "displays forum topics ordered by position" do
      get forum_topics_path
      expect(response.body).to match(/General Discussion.*Cocktail Recipes/m)
    end

    it "displays post and thread counts" do
      thread = create(:forum_thread, forum_topic: topic1)
      create_list(:forum_post, 3, forum_thread: thread)

      get forum_topics_path
      expect(response.body).to include("3") # post count
      expect(response.body).to include("1") # thread count
    end

    it "displays last post information" do
      user = create(:user, username: "testuser")
      thread = create(:forum_thread, forum_topic: topic1)
      post = create(:forum_post, forum_thread: thread, user: user)

      get forum_topics_path
      expect(response.body).to include("testuser")
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "displays unread topics for logged-in user" do
        thread = create(:forum_thread, forum_topic: topic1, updated_at: 1.day.ago)
        create(:forum_post, forum_thread: thread)

        get forum_topics_path
        expect(response).to have_http_status(:success)
        # Should highlight unread topics with CSS class
        expect(response.body).to include("unread-forum-thread")
      end

      it "does not highlight read topics" do
        thread = create(:forum_thread, forum_topic: topic1, updated_at: 3.days.ago)
        create(:forum_post, forum_thread: thread)
        thread.track_visit(user)

        get forum_topics_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "allows access without login" do
        get forum_topics_path
        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to(new_session_path)
      end
    end
  end
end
