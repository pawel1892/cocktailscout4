require 'rails_helper'

RSpec.describe "ForumThreads", type: :request do
  describe "GET /cocktailforum/kategorie/:id (threads index)" do
    let!(:forum_topic) { create(:forum_topic, name: "General", slug: "general") }
    let!(:thread1) { create(:forum_thread, forum_topic: forum_topic, title: "Hello World", updated_at: 2.hours.ago) }
    let!(:thread2) { create(:forum_thread, forum_topic: forum_topic, title: "Goodbye World", updated_at: 1.hour.ago) }

    it "returns http success" do
      get forum_topic_path(forum_topic.slug)
      expect(response).to have_http_status(:success)
    end

    it "displays the forum topic name in breadcrumb" do
      get forum_topic_path(forum_topic.slug)
      expect(response.body).to include("General")
    end

    it "displays threads in the topic" do
      get forum_topic_path(forum_topic.slug)
      expect(response.body).to include("Hello World")
      expect(response.body).to include("Goodbye World")
    end

    it "displays threads ordered by updated_at descending" do
      get forum_topic_path(forum_topic.slug)
      expect(response.body).to match(/Goodbye World.*Hello World/m)
    end

    it "displays thread statistics" do
      create_list(:forum_post, 5, forum_thread: thread1)
      thread1.update_columns(visits_count: 10)

      get forum_topic_path(forum_topic.slug)
      expect(response.body).to include("10") # views
      expect(response.body).to include("5")  # posts
    end

    it "displays last post user and time" do
      user = create(:user, username: "lastposter")
      create(:forum_post, forum_thread: thread1, user: user)

      get forum_topic_path(forum_topic.slug)
      expect(response.body).to include("lastposter")
    end

    context "with pagination" do
      before do
        create_list(:forum_thread, 25, forum_topic: forum_topic)
      end

      it "paginates threads" do
        get forum_topic_path(forum_topic.slug)
        expect(response).to have_http_status(:success)
        # Should show 20 threads per page by default
      end

      it "shows second page" do
        get forum_topic_path(forum_topic.slug, page: 2)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "highlights unread threads" do
        create(:forum_post, forum_thread: thread1)

        get forum_topic_path(forum_topic.slug)
        expect(response.body).to include("unread-indicator")
      end

      it "does not highlight read threads" do
        create(:forum_post, forum_thread: thread1, created_at: 2.hours.ago)
        thread1.track_visit(user)

        get forum_topic_path(forum_topic.slug)
        expect(response).to have_http_status(:success)
      end

      it "does not highlight threads without recent posts" do
        old_thread = create(:forum_thread, forum_topic: forum_topic, updated_at: 2.weeks.ago)

        get forum_topic_path(forum_topic.slug)
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "allows access without login" do
        get forum_topic_path(forum_topic.slug)
        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to(new_session_path)
      end
    end

    it "returns 404 for non-existent topic" do
      get forum_topic_path("non-existent-topic")
      expect(response).to have_http_status(:not_found)
    end

    context "with deleted threads" do
      it "does not display deleted threads" do
        deleted_thread = create(:forum_thread, forum_topic: forum_topic, title: "Deleted Thread", deleted: true)

        get forum_topic_path(forum_topic.slug)
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Deleted Thread")
      end

      it "only counts non-deleted threads in statistics" do
        create(:forum_thread, forum_topic: forum_topic, deleted: true)
        create(:forum_thread, forum_topic: forum_topic, deleted: true)

        get forum_topic_path(forum_topic.slug)
        expect(response).to have_http_status(:success)
        # Should only show the 2 non-deleted threads (thread1 and thread2)
        expect(forum_topic.forum_threads.count).to eq(2)
      end

      it "returns 404 when trying to access deleted thread directly" do
        deleted_thread = create(:forum_thread, forum_topic: forum_topic, title: "Deleted Thread", slug: "deleted-thread", deleted: true)

        get forum_thread_path("deleted-thread")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /cocktailforum/thema/:id (thread show)" do
    let(:forum_topic) { create(:forum_topic, name: "General") }
    let!(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, title: "Discussion Thread", slug: "discussion-thread") }
    let!(:post1) { create(:forum_post, forum_thread: forum_thread, body: "First post", created_at: 2.hours.ago) }
    let!(:post2) { create(:forum_post, forum_thread: forum_thread, body: "Second post", created_at: 1.hour.ago) }

    it "returns http success" do
      get forum_thread_path(forum_thread.slug)
      expect(response).to have_http_status(:success)
    end

    it "displays the thread title in breadcrumb" do
      get forum_thread_path(forum_thread.slug)
      expect(response.body).to include("Discussion Thread")
    end

    it "displays the forum topic in breadcrumb" do
      get forum_thread_path(forum_thread.slug)
      expect(response.body).to include("General")
    end

    it "displays all posts in the thread" do
      get forum_thread_path(forum_thread.slug)
      expect(response.body).to include("First post")
      expect(response.body).to include("Second post")

      # Meta Tags
      expect(response.body).to include("<title>#{forum_thread.title} | CocktailScout</title>")
      expect(response.body).to include('name="description" content="First post"')
    end

    it "displays posts ordered by created_at ascending" do
      get forum_thread_path(forum_thread.slug)
      expect(response.body).to match(/First post.*Second post/m)
    end

    it "displays post user information" do
      user = create(:user, username: "postauthor")
      post = create(:forum_post, forum_thread: forum_thread, user: user)

      get forum_thread_path(forum_thread.slug)
      expect(response.body).to include("postauthor")
    end

    it "displays user post count" do
      user = create(:user)
      create_list(:forum_post, 5, forum_thread: forum_thread, user: user)

      get forum_thread_path(forum_thread.slug)
      expect(response.body).to include("5 Beiträge")
    end

    it "displays post created timestamp" do
      get forum_thread_path(forum_thread.slug)
      expect(response).to have_http_status(:success)
      # Should display formatted timestamp using l() helper
    end

    it "tracks visit for anonymous user" do
      expect {
        get forum_thread_path(forum_thread.slug)
      }.to change { Visit.count }.by(1)

      visit = Visit.last
      expect(visit.user).to be_nil
      expect(visit.visitable).to eq(forum_thread)
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "tracks visit for authenticated user" do
        expect {
          get forum_thread_path(forum_thread.slug)
        }.to change { Visit.count }.by(1)

        visit = Visit.last
        expect(visit.user).to eq(user)
        expect(visit.visitable).to eq(forum_thread)
      end

      it "increments visit count on subsequent visits" do
        get forum_thread_path(forum_thread.slug)
        expect(forum_thread.visits.find_by(user: user).count).to eq(1)

        get forum_thread_path(forum_thread.slug)
        expect(forum_thread.visits.find_by(user: user).count).to eq(2)
      end

      it "updates visits_count on thread" do
        initial_count = forum_thread.visits_count
        get forum_thread_path(forum_thread.slug)
        forum_thread.reload
        expect(forum_thread.visits_count).to eq(initial_count + 1)
      end
    end

    context "with pagination" do
      before do
        create_list(:forum_post, 25, forum_thread: forum_thread)
      end

      it "paginates posts" do
        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        # Should show 20 posts per page by default
      end

      it "shows second page" do
        get forum_thread_path(forum_thread.slug, page: 2)
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "allows access without login" do
        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to(new_session_path)
      end
    end

    it "returns 404 for non-existent thread" do
      get forum_thread_path("non-existent-thread")
      expect(response).to have_http_status(:not_found)
    end

    context "with deleted user" do
      it "displays posts from deleted users" do
        post_with_deleted_user = create(:forum_post, forum_thread: forum_thread, user: nil, body: "Orphaned post")

        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Orphaned post")
        expect(response.body).to include("Gelöschter Benutzer")
      end
    end

    context "with deleted posts" do
      it "does not display deleted posts" do
        deleted_post = create(:forum_post, forum_thread: forum_thread, body: "This post is deleted", deleted: true)

        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("This post is deleted")
      end

      it "still displays non-deleted posts when some posts are deleted" do
        create(:forum_post, forum_thread: forum_thread, body: "Visible post", deleted: false)
        create(:forum_post, forum_thread: forum_thread, body: "Deleted post", deleted: true)

        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Visible post")
        expect(response.body).not_to include("Deleted post")
      end

      it "only counts non-deleted posts in thread statistics" do
        create(:forum_post, forum_thread: forum_thread, deleted: true)
        create(:forum_post, forum_thread: forum_thread, deleted: true)

        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        # Should only count the 2 non-deleted posts (post1 and post2)
        expect(forum_thread.forum_posts.count).to eq(2)
      end

      it "excludes deleted posts from user post count" do
        user = create(:user)
        create(:forum_post, forum_thread: forum_thread, user: user, deleted: false)
        create(:forum_post, forum_thread: forum_thread, user: user, deleted: false)
        create(:forum_post, forum_thread: forum_thread, user: user, deleted: true)

        get forum_thread_path(forum_thread.slug)
        expect(response).to have_http_status(:success)
        # User should show 2 posts, not 3
        expect(user.forum_posts.count).to eq(2)
      end
    end
  end

  describe "POST /cocktailforum/thema/:thread_id/sperren (lock thread)" do
    let(:forum_topic) { create(:forum_topic) }
    let(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, locked: false) }

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin) }

      it "locks the thread" do
        post lock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.locked).to be true
        expect(flash[:notice]).to eq("Thread wurde gesperrt.")
      end
    end

    context "when authenticated as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }

      before { sign_in(moderator) }

      it "locks the thread" do
        post lock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.locked).to be true
      end
    end

    context "when authenticated as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }

      before { sign_in(super_mod) }

      it "locks the thread" do
        post lock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.locked).to be true
      end
    end

    context "when authenticated as regular user" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "denies access" do
        post lock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(root_path)
        expect(forum_thread.reload.locked).to be false
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post lock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(new_session_path)
        expect(forum_thread.reload.locked).to be false
      end
    end
  end

  describe "DELETE /cocktailforum/thema/:thread_id/sperren (unlock thread)" do
    let(:forum_topic) { create(:forum_topic) }
    let(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, locked: true) }

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin) }

      it "unlocks the thread" do
        delete unlock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.locked).to be false
        expect(flash[:notice]).to eq("Thread wurde entsperrt.")
      end
    end

    context "when authenticated as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }

      before { sign_in(moderator) }

      it "unlocks the thread" do
        delete unlock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.locked).to be false
      end
    end

    context "when authenticated as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }

      before { sign_in(super_mod) }

      it "unlocks the thread" do
        delete unlock_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.locked).to be false
      end
    end
  end

  describe "POST /cocktailforum/thema/:thread_id/anpinnen (pin thread)" do
    let(:forum_topic) { create(:forum_topic) }
    let(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, sticky: false) }

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin) }

      it "pins the thread" do
        post pin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.sticky).to be true
        expect(flash[:notice]).to eq("Thread wurde angepinnt.")
      end
    end

    context "when authenticated as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }

      before { sign_in(moderator) }

      it "pins the thread" do
        post pin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.sticky).to be true
      end
    end

    context "when authenticated as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }

      before { sign_in(super_mod) }

      it "pins the thread" do
        post pin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.sticky).to be true
      end
    end

    context "when authenticated as regular user" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "denies access" do
        post pin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(root_path)
        expect(forum_thread.reload.sticky).to be false
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post pin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(new_session_path)
        expect(forum_thread.reload.sticky).to be false
      end
    end
  end

  describe "DELETE /cocktailforum/thema/:thread_id/anpinnen (unpin thread)" do
    let(:forum_topic) { create(:forum_topic) }
    let(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, sticky: true) }

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin) }

      it "unpins the thread" do
        delete unpin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.sticky).to be false
        expect(flash[:notice]).to eq("Thread wurde losgelöst.")
      end
    end

    context "when authenticated as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }

      before { sign_in(moderator) }

      it "unpins the thread" do
        delete unpin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.sticky).to be false
      end
    end

    context "when authenticated as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }

      before { sign_in(super_mod) }

      it "unpins the thread" do
        delete unpin_forum_thread_path(forum_thread)

        expect(response).to redirect_to(forum_thread_path(forum_thread))
        expect(forum_thread.reload.sticky).to be false
      end
    end
  end

  describe "sticky thread ordering in index" do
    let(:forum_topic) { create(:forum_topic) }
    let!(:normal_thread) { create(:forum_thread, forum_topic: forum_topic, title: "Normal Thread", sticky: false, updated_at: 1.hour.ago) }
    let!(:sticky_thread) { create(:forum_thread, forum_topic: forum_topic, title: "Sticky Thread", sticky: true, updated_at: 2.hours.ago) }

    it "displays sticky thread before normal thread" do
      get forum_topic_path(forum_topic)

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/Sticky Thread.*Normal Thread/m)
    end

    it "shows thumbtack icon for sticky thread" do
      get forum_topic_path(forum_topic)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("fa-thumbtack")
    end
  end

  describe "locked thread display" do
    let(:forum_topic) { create(:forum_topic) }
    let(:forum_thread) { create(:forum_thread, forum_topic: forum_topic, title: "Locked Thread", locked: true) }

    it "shows lock icon for locked thread" do
      get forum_thread_path(forum_thread)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("fa-lock")
    end

    context "when not authenticated" do
      it "shows locked message instead of reply button" do
        get forum_thread_path(forum_thread)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dieser Thread ist geschlossen")
        expect(response.body).not_to include("Antworten")
      end
    end

    context "when authenticated as regular user" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "shows locked message instead of reply button" do
        get forum_thread_path(forum_thread)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dieser Thread ist geschlossen")
        expect(response.body).not_to include(new_forum_post_path(forum_thread))
      end
    end

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin) }

      it "shows reply button with moderator label" do
        get forum_thread_path(forum_thread)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Antworten (als Moderator)")
      end

      it "shows lock/unlock and pin/unpin controls" do
        get forum_thread_path(forum_thread)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Entsperren")
      end
    end

    context "when authenticated as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }

      before { sign_in(moderator) }

      it "shows reply button with moderator label" do
        get forum_thread_path(forum_thread)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Antworten (als Moderator)")
      end
    end

    context "when authenticated as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }

      before { sign_in(super_mod) }

      it "shows reply button with moderator label" do
        get forum_thread_path(forum_thread)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Antworten (als Moderator)")
      end
    end
  end
end
