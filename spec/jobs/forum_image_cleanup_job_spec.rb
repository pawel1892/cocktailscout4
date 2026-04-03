require "rails_helper"

RSpec.describe ForumImageCleanupJob, type: :job do
  let(:forum_thread) { create(:forum_thread) }

  def create_image_with_url
    fi = create(:forum_image, :with_image)
    url = "/rails/active_storage/blobs/redirect/#{fi.image.blob.signed_id}/test_image.jpg"
    [ fi, url ]
  end

  describe "#perform" do
    describe "phase 1 — marking abandoned uploads as orphaned" do
      it "marks images older than 2 hours not referenced in any post" do
        fi = create(:forum_image, :with_image, created_at: 3.hours.ago)
        described_class.new.perform
        expect(fi.reload.orphaned_at).to be_present
      end

      it "does not mark images uploaded within the last 2 hours" do
        fi = create(:forum_image, :with_image, created_at: 1.hour.ago)
        described_class.new.perform
        expect(fi.reload.orphaned_at).to be_nil
      end

      it "does not mark images referenced in a live post" do
        fi, url = create_image_with_url
        fi.update_column(:created_at, 3.hours.ago)
        create(:forum_post, forum_thread: forum_thread, body: "![img](#{url})")

        described_class.new.perform

        expect(fi.reload.orphaned_at).to be_nil
      end

      it "does not overwrite an existing orphaned_at timestamp" do
        fi = create(:forum_image, :with_image, :orphaned, created_at: 3.hours.ago)
        original_time = fi.orphaned_at

        described_class.new.perform

        expect(fi.reload.orphaned_at).to eq(original_time)
      end
    end

    describe "phase 2 — purging images orphaned for more than 30 days" do
      it "destroys images with orphaned_at older than 30 days" do
        fi = create(:forum_image, :with_image, :pending_deletion)
        expect {
          described_class.new.perform
        }.to change(ForumImage, :count).by(-1)
        expect(ForumImage.exists?(fi.id)).to be false
      end

      it "keeps images orphaned less than 30 days ago" do
        fi = create(:forum_image, :with_image, :orphaned)
        described_class.new.perform
        expect(ForumImage.exists?(fi.id)).to be true
      end

      it "keeps active (non-orphaned) images" do
        fi = create(:forum_image, :with_image)
        described_class.new.perform
        expect(ForumImage.exists?(fi.id)).to be true
      end
    end
  end
end
