require 'rails_helper'

describe ForumPostsController do

  describe "POST #create" do
    before :each do
      @user = create(:user)
      @post = create(:forum_post)
      @thread = @post.forum_thread
    end

    context "logged in user" do
      it "creates a new post" do
        sign_in @user
        expect {
          post :create, params: {thread_id: @thread.slug, forum_post: {content: 'post'}}
        }.to change(ForumPost, :count).by(1)
      end
    end

    context "user not logged in" do
      it "denies access" do
        post :create, params: {thread_id: @thread.slug, forum_post: {content: 'post'}}
        expect(response).to require_login
      end
    end
  end

  describe "PATCH #update" do
    before :each do
      @user = create(:user)
      @forum_moderator = create(:forum_moderator_user)
      @post = create(:forum_post, user: @user)
      @moderator_post = create(:forum_post, user: @forum_moderator)
    end

    context "logged in user" do
      it "changes content in a post from the user" do
        sign_in @user
        patch :update, params: {id: @post.id, forum_post: {content: 'edited post'}}
        expect(@post.reload.content).to eq('edited post')
      end
      it "denies access for posts of other users" do
        sign_in @user
        patch :update, params: {id: @moderator_post.id, forum_post: {content: 'edited post'}}
        expect(@post.reload.content).not_to eq('edited post')
      end
    end

    context "user not logged in" do
      it "denies access" do
        patch :update, params: { id: @post.id }
        expect(response).to require_login
      end
    end
  end

  describe 'DELETE #destroy'do
    before :each do
      @user = create(:user)
      @forum_moderator = create(:forum_moderator_user)
      @post = create(:forum_post, user: @user)
    end
    context "logged in user with role member" do
      it "does not delete the post (wrong role)" do
        sign_in @user
        expect{
          delete :destroy, params: {id: @post.id}
        }.not_to change(ForumPost,:count)
      end
    end
    context "logged in user with role moderator" do
      it "deletes the post" do
        sign_in @forum_moderator
        expect{
          delete :destroy, params: { id: @post.id }
        }.to change(ForumPost,:count).by(-1)
      end
    end
  end

end
