require 'rails_helper'

describe ForumThreadForm do
  context "valid thread" do
    before :each do
      @forum_thread_form = ForumThreadForm.new(
          thread_title: 'title',
          post_content: 'post',
          user: create(:user),
          forum_topic: create(:forum_topic)
      )
    end
    it "saves valid posts" do
      expect{
        @forum_thread_form.save
      }.to  change(ForumThread, :count).by(1)
    end
  end
end