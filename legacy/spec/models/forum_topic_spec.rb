require 'rails_helper'

describe ForumTopic do
  it "has a valid factory" do
    expect(FactoryGirl.create(:forum_topic)).to be_valid
  end

  it "counts threads" do
    topic = FactoryGirl.create(:forum_topic)
    FactoryGirl.create(:forum_thread, :forum_topic => topic)
    FactoryGirl.create(:forum_thread, :forum_topic => topic)
    expect(topic.reload.thread_count).to eq 2
  end

  it "counts posts" do
    topic = FactoryGirl.create(:forum_topic)
    thread = FactoryGirl.create(:forum_thread, :forum_topic => topic)
    thread.forum_posts << ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli')
    thread.save
    FactoryGirl.create(:forum_thread, :forum_topic => topic)
    expect(topic.reload.post_count).to eq 3
  end

  it "caches the last post" do
    topic = FactoryGirl.create(:forum_topic)
    FactoryGirl.create(:forum_thread, :forum_topic => topic)
    thread = FactoryGirl.create(:forum_thread, :forum_topic => topic)
    post = ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli')
    thread.forum_posts << post
    thread.save
    expect(topic.reload.last_post).to eq post
  end
end
