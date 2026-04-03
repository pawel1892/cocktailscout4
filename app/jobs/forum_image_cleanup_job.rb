class ForumImageCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # Phase 1: mark abandoned uploads as orphaned
    # Images uploaded > 2 hours ago that aren't referenced in any live post body
    ForumImage.not_marked_as_orphaned.where("created_at < ?", 2.hours.ago).find_each do |fi|
      fi.mark_as_orphan! unless fi.referenced_in_any_live_post?
    end

    # Phase 2: permanently delete images orphaned for > 30 days
    ForumImage.pending_deletion.find_each do |fi|
      fi.image.purge_later
      fi.destroy
    end
  end
end
