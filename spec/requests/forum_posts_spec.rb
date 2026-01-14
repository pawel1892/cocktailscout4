require 'rails_helper'

RSpec.describe "ForumPosts", type: :request do
  include AuthenticationHelpers

  let(:user) { create(:user) }
  let(:forum_topic) { create(:forum_topic) }
  let(:forum_thread) { create(:forum_thread, forum_topic: forum_topic) }
  let!(:forum_post) { create(:forum_post, forum_thread: forum_thread, user: user) }

  describe "GET /cocktailforum/thema/:thread_id/beitrag/neu" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get new_forum_post_path(forum_thread)
        expect(response).to have_http_status(:success)
      end

      it "handles quoting a post" do
        other_post = create(:forum_post, forum_thread: forum_thread, body: "Original content")
        get new_forum_post_path(forum_thread, quote: other_post.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("[quote=#{other_post.user.username}]Original content[/quote]")
      end

      it "handles quoting a post with missing user" do
        other_post = create(:forum_post, forum_thread: forum_thread, body: "Original content", user: nil)
        get new_forum_post_path(forum_thread, quote: other_post.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("[quote=Gast]Original content[/quote]")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_forum_post_path(forum_thread)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /cocktailforum/thema/:thread_id/beitrag" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a new post" do
        expect {
          post forum_posts_path(forum_thread), params: { forum_post: { body: "New post body" } }
        }.to change(ForumPost, :count).by(1)

        expect(response).to redirect_to(forum_thread_path(forum_thread, page: 1, anchor: "post-#{ForumPost.last.id}"))
      end

      it "fails with invalid data" do
                expect {
                  post forum_posts_path(forum_thread), params: { forum_post: { body: "" } }
                }.not_to change(ForumPost, :count)

                expect(response).to have_http_status(:unprocessable_content)
              end
            end
          end
  describe "GET /cocktailforum/beitrag/:id/bearbeiten" do
    context "when authenticated as author" do
      before { sign_in(user) }

      it "returns http success" do
        get edit_forum_post_path(forum_post)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects with alert" do
        get edit_forum_post_path(forum_post)
        expect(response).to redirect_to(forum_thread_path(forum_thread))
        follow_redirect!
        expect(response.body).to include("Du hast keine Berechtigung")
      end
    end

    context "with deleted post" do
      before { sign_in(user) }
      let!(:deleted_post) { create(:forum_post, forum_thread: forum_thread, user: user, deleted: true) }

      it "returns 404" do
        get edit_forum_post_path(deleted_post)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /cocktailforum/beitrag/:id" do
    context "when authenticated as author" do
      before { sign_in(user) }

      it "updates the post" do
        patch forum_post_path(forum_post), params: { forum_post: { body: "Updated body" } }
        forum_post.reload
        expect(forum_post.body).to eq("Updated body")
        expect(forum_post.last_editor).to eq(user)
        expect(response).to redirect_to(forum_thread_path(forum_thread, page: 1, anchor: "post-#{forum_post.id}"))
      end
    end

    context "with deleted post" do
      before { sign_in(user) }
      let!(:deleted_post) { create(:forum_post, forum_thread: forum_thread, user: user, deleted: true) }

      it "returns 404" do
        patch forum_post_path(deleted_post), params: { forum_post: { body: "Updated body" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /cocktailforum/beitrag/:id" do
    context "when authenticated as author" do
      before { sign_in(user) }

      it "denies deletion" do
        delete forum_post_path(forum_post)
        expect(response).to redirect_to(forum_thread_path(forum_thread))
        follow_redirect!
        expect(response.body).to include("Du hast keine Berechtigung, diesen Beitrag zu löschen")

        forum_post.reload
        expect(forum_post.deleted).to be(false)
      end
    end

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }
      before { sign_in(admin) }

      it "soft deletes the post" do
        create(:forum_post, forum_thread: forum_thread) # Ensure thread has another post
        delete forum_post_path(forum_post)
        forum_post.reload
        expect(forum_post.deleted).to be(true)
        expect(response).to redirect_to(forum_thread_path(forum_thread))
      end

      it "soft deletes the thread if it was the last post" do
        # forum_post is the only post in forum_thread
        delete forum_post_path(forum_post)

        forum_thread.reload
        expect(forum_thread.deleted).to be(true)
        expect(response).to redirect_to(forum_topic_path(forum_thread.forum_topic))
      end
    end
  end
end
