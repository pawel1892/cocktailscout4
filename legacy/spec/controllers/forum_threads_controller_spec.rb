require 'rails_helper'

describe ForumThreadsController do

  describe "POST #create" do
    before :each do
      @user = create(:user)
      @topic = create(:forum_topic)
    end

    context "logged in user" do
      it "creates a new thread" do
        sign_in @user
        expect {
          post :create, params: {:topic_id => @topic.slug, :forum_thread_form => {thread_title: 'title', post_content: 'post'}}
        }.to change(ForumThread, :count).by(1)
      end
    end

    context "user not logged in" do
      it "denies access" do
        post :create, params: { topic_id: @topic.slug }
        expect(response).to require_login
      end
    end

  end

end
