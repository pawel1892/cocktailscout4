require 'rails_helper'

RSpec.describe "Forum Search", type: :request do
  let!(:topic) { create(:forum_topic) }
  let!(:thread1) { create(:forum_thread, title: "Best Mojito Recipe", forum_topic: topic) }
  let!(:thread2) { create(:forum_thread, title: "Vodka Discussion", forum_topic: topic) }
  let!(:post1) { create(:forum_post, body: "I love mint in my drinks", forum_thread: thread1) }
  let!(:post2) { create(:forum_post, body: "Potato based spirits are great", forum_thread: thread2) }

  describe "GET /cocktailforum/suche" do
    it "renders the search page" do
      get forum_search_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Suche")
    end

        it "searches threads by title" do
          get forum_search_path(q: "Mojito")

          expect(response.body).to include(thread1.title)
          expect(response.body).not_to include(thread2.title)
        end

        it "searches threads by post content" do
          get forum_search_path(q: "Potato")

          expect(response.body).to include(thread2.title)
          expect(response.body).not_to include(thread1.title)
        end

        it "handles no results" do
          get forum_search_path(q: "NonExistent")

          expect(response.body).to include("Keine Themen gefunden")
        end

        it "links to the specific matching post" do
          get forum_search_path(q: "Potato")

          # Expect the link to contain the anchor
          expect(response.body).to include("#post-#{post2.id}")
        end  end
end
