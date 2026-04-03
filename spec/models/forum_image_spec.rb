require 'rails_helper'

RSpec.describe ForumImage, type: :model do
  let(:user) { create(:user) }

  def create_image_with_url
    fi = create(:forum_image, :with_image, user: user)
    url = "/rails/active_storage/blobs/redirect/#{fi.image.blob.signed_id}/test_image.jpg"
    [ fi, url ]
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
  end

  describe "scopes" do
    describe ".marked_as_orphaned" do
      it "returns only images with orphaned_at set" do
        orphaned = create(:forum_image, :with_image, :orphaned, user: user)
        _active  = create(:forum_image, :with_image, user: user)
        expect(ForumImage.marked_as_orphaned).to contain_exactly(orphaned)
      end
    end

    describe ".not_marked_as_orphaned" do
      it "returns only images without orphaned_at" do
        _orphaned = create(:forum_image, :with_image, :orphaned, user: user)
        active    = create(:forum_image, :with_image, user: user)
        expect(ForumImage.not_marked_as_orphaned).to contain_exactly(active)
      end
    end

    describe ".pending_deletion" do
      it "returns images with orphaned_at older than 30 days" do
        old     = create(:forum_image, :with_image, :pending_deletion, user: user)
        recent  = create(:forum_image, :with_image, :orphaned, user: user)
        _active = create(:forum_image, :with_image, user: user)
        expect(ForumImage.pending_deletion).to contain_exactly(old)
      end
    end
  end

  describe ".signed_ids_in_body" do
    it "extracts signed_ids from redirect blob URLs" do
      result = ForumImage.signed_ids_in_body(
        "Hello ![img](/rails/active_storage/blobs/redirect/abc123/img.jpg) world"
      )
      expect(result).to eq(Set["abc123"])
    end

    it "extracts signed_ids from proxy blob URLs" do
      result = ForumImage.signed_ids_in_body(
        "/rails/active_storage/blobs/proxy/xyz789/photo.png"
      )
      expect(result).to eq(Set["xyz789"])
    end

    it "extracts multiple signed_ids" do
      result = ForumImage.signed_ids_in_body(
        "/rails/active_storage/blobs/redirect/aaa/a.jpg text /rails/active_storage/blobs/redirect/bbb/b.jpg"
      )
      expect(result).to eq(Set["aaa", "bbb"])
    end

    it "returns empty set for body with no images" do
      expect(ForumImage.signed_ids_in_body("just some text")).to be_empty
    end
  end

  describe ".detect_orphans" do
    it "returns images whose blob is not referenced in any live post" do
      orphan, _url = create_image_with_url
      expect(ForumImage.detect_orphans).to include(orphan)
    end

    it "excludes images referenced in a live post" do
      fi, url = create_image_with_url
      thread = create(:forum_thread)
      create(:forum_post, forum_thread: thread, body: "Look: #{url}")
      expect(ForumImage.detect_orphans).not_to include(fi)
    end

    it "excludes images already marked as orphaned" do
      fi, _url = create_image_with_url
      fi.update!(orphaned_at: 1.hour.ago)
      expect(ForumImage.detect_orphans).not_to include(fi)
    end
  end

  describe "#referenced_in_any_live_post?" do
    it "returns false when no posts reference the image" do
      fi, _url = create_image_with_url
      expect(fi.referenced_in_any_live_post?).to be false
    end

    it "returns true when a live post references the image" do
      fi, url = create_image_with_url
      thread = create(:forum_thread)
      create(:forum_post, forum_thread: thread, body: "![img](#{url})")
      expect(fi.referenced_in_any_live_post?).to be true
    end

    it "returns false when only a deleted post references the image" do
      fi, url = create_image_with_url
      thread = create(:forum_thread)
      post = create(:forum_post, forum_thread: thread, body: "![img](#{url})")
      post.update_column(:deleted, true)
      expect(fi.referenced_in_any_live_post?).to be false
    end

    it "returns false when excluding the only referencing post" do
      fi, url = create_image_with_url
      thread = create(:forum_thread)
      post = create(:forum_post, forum_thread: thread, body: "![img](#{url})")
      expect(fi.referenced_in_any_live_post?(exclude_post_id: post.id)).to be false
    end

    it "returns true when another post also references the image" do
      fi, url = create_image_with_url
      thread = create(:forum_thread)
      post1 = create(:forum_post, forum_thread: thread, body: "![img](#{url})")
      _post2 = create(:forum_post, forum_thread: thread, body: "Also here: #{url}")
      expect(fi.referenced_in_any_live_post?(exclude_post_id: post1.id)).to be true
    end
  end

  describe "#mark_as_orphan!" do
    it "sets orphaned_at" do
      fi = create(:forum_image, :with_image, user: user)
      expect { fi.mark_as_orphan! }.to change { fi.reload.orphaned_at }.from(nil)
    end

    it "is idempotent — does not overwrite existing orphaned_at" do
      fi = create(:forum_image, :with_image, :orphaned, user: user)
      original_time = fi.orphaned_at
      fi.mark_as_orphan!
      expect(fi.reload.orphaned_at).to eq(original_time)
    end
  end

  describe "#restore!" do
    it "clears orphaned_at" do
      fi = create(:forum_image, :with_image, :orphaned, user: user)
      expect { fi.restore! }.to change { fi.reload.orphaned_at }.to(nil)
    end
  end

  describe "#orphaned?" do
    it "returns false when orphaned_at is nil" do
      fi = build(:forum_image, :with_image, orphaned_at: nil)
      expect(fi.orphaned?).to be false
    end

    it "returns true when orphaned_at is set" do
      fi = build(:forum_image, :with_image, :orphaned)
      expect(fi.orphaned?).to be true
    end
  end
end
