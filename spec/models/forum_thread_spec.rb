require 'rails_helper'

RSpec.describe ForumThread, type: :model do
  include_examples "visitable"

  describe "Associations" do
    it { is_expected.to belong_to(:forum_topic) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:forum_posts).dependent(:destroy) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:forum_topic) }
  end

  describe "#views" do
    let(:forum_thread) { create(:forum_thread) }
    let(:user) { create(:user) }

    context "when visits_count is positive" do
      it "returns visits_count" do
        forum_thread.update_columns(visits_count: 5)
        expect(forum_thread.views).to eq(5)
      end
    end

    context "when visits_count is zero" do
      it "returns total_visits" do
        forum_thread.track_visit(user)
        forum_thread.track_visit(user)
        expect(forum_thread.views).to eq(2)
      end
    end
  end

  describe "#count_posts" do
    let(:forum_thread) { create(:forum_thread) }

    it "returns the number of posts in the thread" do
      create_list(:forum_post, 3, forum_thread: forum_thread)
      expect(forum_thread.count_posts).to eq(3)
    end

    it "returns 0 when there are no posts" do
      expect(forum_thread.count_posts).to eq(0)
    end
  end

  describe "#ordered_posts" do
    let(:forum_thread) { create(:forum_thread) }

    it "returns posts ordered by created_at ascending" do
      post3 = create(:forum_post, forum_thread: forum_thread, created_at: 3.hours.ago)
      post1 = create(:forum_post, forum_thread: forum_thread, created_at: 5.hours.ago)
      post2 = create(:forum_post, forum_thread: forum_thread, created_at: 4.hours.ago)

      expect(forum_thread.ordered_posts).to eq([ post1, post2, post3 ])
    end
  end

  describe "#ordered_posts_by_page" do
    let(:forum_thread) { create(:forum_thread) }

    before do
      create_list(:forum_post, 25, forum_thread: forum_thread)
    end

    it "returns paginated posts" do
      page1 = forum_thread.ordered_posts_by_page(1, 20)
      expect(page1.count).to eq(20)
    end

    it "returns remaining posts on second page" do
      page2 = forum_thread.ordered_posts_by_page(2, 20)
      expect(page2.count).to eq(5)
    end
  end

  describe "#last_post" do
    let(:forum_thread) { create(:forum_thread) }

    it "returns the most recent post" do
      old_post = create(:forum_post, forum_thread: forum_thread, created_at: 2.hours.ago)
      recent_post = create(:forum_post, forum_thread: forum_thread, created_at: 1.hour.ago)

      expect(forum_thread.last_post).to eq(recent_post)
    end

    it "returns nil when there are no posts" do
      expect(forum_thread.last_post).to be_nil
    end
  end

  describe "#read_by?" do
    let(:forum_thread) { create(:forum_thread) }
    let(:user) { create(:user) }

    context "when user has visited after last post" do
      it "returns true" do
        create(:forum_post, forum_thread: forum_thread, created_at: 2.hours.ago)
        forum_thread.track_visit(user)

        expect(forum_thread.read_by?(user)).to be true
      end
    end

    context "when user has not visited" do
      it "returns false" do
        create(:forum_post, forum_thread: forum_thread)
        expect(forum_thread.read_by?(user)).to be false
      end
    end

    context "when user visited before last post" do
      it "returns false" do
        forum_thread.track_visit(user)
        create(:forum_post, forum_thread: forum_thread)

        expect(forum_thread.read_by?(user)).to be false
      end
    end

    context "when there are no posts" do
      it "returns false" do
        expect(forum_thread.read_by?(user)).to be false
      end
    end
  end

  describe "#first_unread_post" do
    let(:forum_thread) { create(:forum_thread) }
    let(:user) { create(:user) }

    context "when user has visited" do
      it "returns first post after last visit" do
        post1 = create(:forum_post, forum_thread: forum_thread, created_at: 3.hours.ago)
        post2 = create(:forum_post, forum_thread: forum_thread, created_at: 2.hours.ago)

        # Simulate a visit that happened 90 minutes ago
        visit = forum_thread.visits.create!(user: user, count: 1)
        visit.update_column(:last_visited_at, 90.minutes.ago)

        post3 = create(:forum_post, forum_thread: forum_thread, created_at: 1.hour.ago)

        expect(forum_thread.first_unread_post(user)).to eq(post3)
      end
    end

    context "when user has not visited" do
      it "returns first post" do
        post1 = create(:forum_post, forum_thread: forum_thread, created_at: 3.hours.ago)
        post2 = create(:forum_post, forum_thread: forum_thread, created_at: 2.hours.ago)

        expect(forum_thread.first_unread_post(user)).to eq(post1)
      end
    end
  end

  describe "#last_post_user" do
    let(:forum_thread) { create(:forum_thread) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "returns user of the most recent post" do
      create(:forum_post, forum_thread: forum_thread, user: user1, created_at: 2.hours.ago)
      create(:forum_post, forum_thread: forum_thread, user: user2, created_at: 1.hour.ago)

      expect(forum_thread.last_post_user).to eq(user2)
    end

    it "returns nil when there are no posts" do
      expect(forum_thread.last_post_user).to be_nil
    end
  end

  describe "#last_post_created_at" do
    let(:forum_thread) { create(:forum_thread) }

    it "returns created_at of the most recent post" do
      create(:forum_post, forum_thread: forum_thread, created_at: 2.hours.ago)
      recent_post = create(:forum_post, forum_thread: forum_thread, created_at: 1.hour.ago)

      expect(forum_thread.last_post_created_at).to eq(recent_post.created_at)
    end

    it "returns nil when there are no posts" do
      expect(forum_thread.last_post_created_at).to be_nil
    end
  end

  describe ".last_active_threads scope" do
    let!(:thread1) { create(:forum_thread, updated_at: 3.days.ago) }
    let!(:thread2) { create(:forum_thread, updated_at: 1.day.ago) }
    let!(:thread3) { create(:forum_thread, updated_at: 2.days.ago) }

    it "returns threads ordered by updated_at descending" do
      expect(ForumThread.last_active_threads).to eq([ thread2, thread3, thread1 ])
    end
  end
end
