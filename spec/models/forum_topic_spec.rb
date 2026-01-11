require 'rails_helper'

RSpec.describe ForumTopic, type: :model do
  describe "Associations" do
    it { is_expected.to have_many(:forum_threads) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "#post_count" do
    let(:forum_topic) { create(:forum_topic) }
    let(:thread1) { create(:forum_thread, forum_topic: forum_topic) }
    let(:thread2) { create(:forum_thread, forum_topic: forum_topic) }

    it "returns total count of posts across all threads" do
      create(:forum_post, forum_thread: thread1)
      create(:forum_post, forum_thread: thread1)
      create(:forum_post, forum_thread: thread2)

      expect(forum_topic.post_count).to eq(3)
    end

    it "returns 0 when there are no posts" do
      expect(forum_topic.post_count).to eq(0)
    end
  end

  describe "#thread_count" do
    let(:forum_topic) { create(:forum_topic) }

    it "returns count of threads in the topic" do
      create_list(:forum_thread, 3, forum_topic: forum_topic)

      expect(forum_topic.thread_count).to eq(3)
    end

    it "returns 0 when there are no threads" do
      expect(forum_topic.thread_count).to eq(0)
    end
  end

  describe "#last_post" do
    let(:forum_topic) { create(:forum_topic) }
    let(:thread1) { create(:forum_thread, forum_topic: forum_topic) }
    let(:thread2) { create(:forum_thread, forum_topic: forum_topic) }

    it "returns the most recent post across all threads" do
      old_post = create(:forum_post, forum_thread: thread1, created_at: 2.hours.ago)
      recent_post = create(:forum_post, forum_thread: thread2, created_at: 1.hour.ago)

      expect(forum_topic.last_post).to eq(recent_post)
    end

    it "returns nil when there are no posts" do
      expect(forum_topic.last_post).to be_nil
    end
  end

  describe ".unread_by scope" do
    let(:user) { create(:user) }
    let(:topic_with_unread) { create(:forum_topic) }
    let(:topic_with_read) { create(:forum_topic) }
    let(:topic_without_posts) { create(:forum_topic) }

    before do
      # Topic with unread thread
      unread_thread = create(:forum_thread, forum_topic: topic_with_unread, updated_at: 1.day.ago)
      create(:forum_post, forum_thread: unread_thread)

      # Topic with read thread
      read_thread = create(:forum_thread, forum_topic: topic_with_read, updated_at: 3.days.ago)
      create(:forum_post, forum_thread: read_thread)
      read_thread.track_visit(user)
    end

    it "returns topics with unread threads from the last week" do
      unread_topics = ForumTopic.unread_by(user)
      expect(unread_topics).to include(topic_with_unread)
      expect(unread_topics).not_to include(topic_with_read)
      expect(unread_topics).not_to include(topic_without_posts)
    end
  end
end
