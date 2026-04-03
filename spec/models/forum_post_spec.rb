require 'rails_helper'

RSpec.describe ForumPost, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:forum_thread) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "public_id generation" do
    let(:forum_thread) { create(:forum_thread) }

    it "automatically generates a public_id on creation" do
      post = create(:forum_post, forum_thread: forum_thread)
      expect(post.public_id).to be_present
      expect(post.public_id).to match(/^[a-zA-Z0-9]{8}$/)
    end

    it "generates unique public_ids" do
      post1 = create(:forum_post, forum_thread: forum_thread)
      post2 = create(:forum_post, forum_thread: forum_thread)
      expect(post1.public_id).not_to eq(post2.public_id)
    end

    it "does not change public_id on update" do
      post = create(:forum_post, forum_thread: forum_thread)
      original_public_id = post.public_id
      post.update(body: "Updated body")
      expect(post.public_id).to eq(original_public_id)
    end
  end

  describe "#page" do
    let(:forum_thread) { create(:forum_thread) }
    let!(:post1) { create(:forum_post, forum_thread: forum_thread, created_at: 5.hours.ago) }
    let!(:post2) { create(:forum_post, forum_thread: forum_thread, created_at: 4.hours.ago) }
    let!(:post3) { create(:forum_post, forum_thread: forum_thread, created_at: 3.hours.ago) }

    context "with default per_page of 20" do
      it "returns 1 for posts 1-20" do
        expect(post1.page).to eq(1)
        expect(post2.page).to eq(1)
        expect(post3.page).to eq(1)
      end

      it "returns 2 for post 21" do
        create_list(:forum_post, 17, forum_thread: forum_thread, created_at: 2.hours.ago)
        post21 = create(:forum_post, forum_thread: forum_thread, created_at: 1.hour.ago)

        expect(post21.page).to eq(2)
      end
    end

    context "with custom per_page" do
      it "calculates page based on custom per_page" do
        create_list(:forum_post, 7, forum_thread: forum_thread)
        last_post = create(:forum_post, forum_thread: forum_thread)

        expect(last_post.page(5)).to eq(3) # 11 posts total, 5 per page = page 3
      end
    end
  end

  describe "#user_post_count" do
    let(:user) { create(:user) }
    let(:forum_thread) { create(:forum_thread) }

    it "returns count of posts by the user" do
      create_list(:forum_post, 3, user: user, forum_thread: forum_thread)
      post = forum_thread.forum_posts.first

      expect(post.user_post_count).to eq(3)
    end

    it "returns 0 when user has no posts" do
      post = create(:forum_post, forum_thread: forum_thread, user: user)
      post.user.forum_posts.delete_all

      expect(post.reload.user_post_count).to eq(0)
    end

    it "returns 0 when user is nil" do
      post = create(:forum_post, forum_thread: forum_thread, user: nil)
      expect(post.user_post_count).to eq(0)
    end
  end

  describe "forum image orphan callbacks" do
    let(:forum_thread) { create(:forum_thread) }

    def create_image_with_url
      fi = create(:forum_image, :with_image)
      url = "/rails/active_storage/blobs/redirect/#{fi.image.blob.signed_id}/test_image.jpg"
      [ fi, url ]
    end

    describe "#orphan_removed_images — on body update" do
      it "marks images removed from the body as orphaned" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")

        post.update!(body: "updated without image")

        expect(fi.reload.orphaned_at).to be_present
      end

      it "does not mark images still present in the body" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")

        post.update!(body: "still here: #{url}")

        expect(fi.reload.orphaned_at).to be_nil
      end

      it "does not mark images that are still used in another live post" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")
        _other = create(:forum_post, forum_thread: forum_thread, body: "also: #{url}")

        post.update!(body: "updated without image")

        expect(fi.reload.orphaned_at).to be_nil
      end

      it "does not fire when body is unchanged" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")

        expect(fi).not_to receive(:mark_as_orphan!)
        post.update!(body: "![img](#{url})")
      end
    end

    describe "#orphan_deleted_post_images — on soft-delete" do
      it "marks images in the deleted post as orphaned" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")

        post.update!(deleted: true)

        expect(fi.reload.orphaned_at).to be_present
      end

      it "does not mark images also used in another live post" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")
        _other = create(:forum_post, forum_thread: forum_thread, body: "also: #{url}")

        post.update!(deleted: true)

        expect(fi.reload.orphaned_at).to be_nil
      end

      it "does not fire when post is not being deleted" do
        fi, url = create_image_with_url
        post = create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")

        expect(fi).not_to receive(:mark_as_orphan!)
        post.update!(body: "![img](#{url})")
      end
    end
  end

  describe "user stats update" do
    let(:user) { create(:user) }
    let(:forum_thread) { create(:forum_thread) }

    it "updates user stats after creating a post" do
      expect {
        create(:forum_post, forum_thread: forum_thread, user: user)
      }.to change { user.stat.reload.points }.by(3)
    end

    it "updates user stats when post is soft deleted" do
      post = create(:forum_post, forum_thread: forum_thread, user: user)
      initial_points = user.stat.reload.points

      post.update(deleted: true)

      expect(user.stat.reload.points).to eq(initial_points - 3)
    end

    it "does not raise error when user is nil" do
      expect {
        create(:forum_post, forum_thread: forum_thread, user: nil)
      }.not_to raise_error
    end
  end
end
