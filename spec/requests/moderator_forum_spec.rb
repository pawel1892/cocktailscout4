require 'rails_helper'

RSpec.describe "Moderators-only forum topic", type: :request do
  let!(:public_topic) { create(:forum_topic, name: "Allgemeine Diskussion", slug: "allgemeine-diskussion", position: 0) }
  let!(:mod_topic) { create(:forum_topic, :moderators_only, name: "Moderatorentalk", slug: "moderatorentalk", position: -100) }
  let!(:mod_thread) { create(:forum_thread, forum_topic: mod_topic, title: "Geheimer Modthread", slug: "geheimer-modthread") }
  let!(:mod_post) { create(:forum_post, forum_thread: mod_thread, body: "Streng vertraulicher Inhalt") }
  let!(:public_thread) { create(:forum_thread, forum_topic: public_topic, title: "Offener Thread", slug: "offener-thread") }
  let!(:public_post) { create(:forum_post, forum_thread: public_thread, body: "Oeffentlicher Inhalt") }

  shared_examples "hides the moderator forum" do
    it "does not list the topic in the forum overview" do
      get forum_topics_path
      expect(response.body).to include("Allgemeine Diskussion")
      expect(response.body).not_to include("Moderatorentalk")
    end

    it "returns 404 for the topic page" do
      get forum_topic_path(mod_topic)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a thread in the topic" do
      get forum_thread_path(mod_thread)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a post permalink in the topic" do
      get show_forum_post_path(mod_post.public_id)
      expect(response).to have_http_status(:not_found)
    end

    it "does not return threads of the topic in search" do
      get forum_search_path, params: { q: "vertraulicher" }
      expect(response.body).not_to include("Geheimer Modthread")
    end
  end

  context "as guest" do
    include_examples "hides the moderator forum"
  end

  context "as regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    include_examples "hides the moderator forum"

    it "cannot create a thread in the topic" do
      expect {
        post create_forum_thread_path(mod_topic), params: { forum_thread_form: { thread_title: "Hallo", post_content: "Test" } }
      }.not_to change(ForumThread, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot reply in a thread of the topic" do
      expect {
        post forum_posts_path(mod_thread), params: { forum_post: { body: "Test" } }
      }.not_to change(ForumPost, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot quote a post of the topic in a public thread" do
      get new_forum_post_path(public_thread, quote: mod_post.id)
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Streng vertraulicher Inhalt")
    end
  end

  context "as wiki editor" do
    let(:user) { create(:user, :wiki_editor) }
    before { sign_in(user) }

    include_examples "hides the moderator forum"
  end

  %i[admin forum_moderator recipe_moderator image_moderator super_moderator].each do |role|
    context "as #{role}" do
      let(:user) { create(:user, role) }
      before { sign_in(user) }

      it "lists the topic above the public topics" do
        get forum_topics_path
        expect(response.body).to match(/Moderatorentalk.*Allgemeine Diskussion/m)
      end

      it "can open the topic and its threads" do
        get forum_topic_path(mod_topic)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Geheimer Modthread")

        get forum_thread_path(mod_thread)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Streng vertraulicher Inhalt")
      end

      it "can reply in a thread of the topic" do
        expect {
          post forum_posts_path(mod_thread), params: { forum_post: { body: "Antwort vom Team" } }
        }.to change(ForumPost, :count).by(1)
      end

      it "finds threads of the topic in search" do
        get forum_search_path, params: { q: "vertraulicher" }
        expect(response.body).to include("Geheimer Modthread")
      end
    end
  end

  describe "activity stream" do
    it "excludes posts from the moderator forum" do
      events = ActivityStreamService.new(limit: 50).call.select { |e| e[:type] == "forum_post" }
      expect(events.map { |e| e.dig(:meta, :thread_title) }).to contain_exactly("Offener Thread")
    end
  end
end
