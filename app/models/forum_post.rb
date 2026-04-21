class ForumPost < ApplicationRecord
  include Reportable
  include Visitable
  has_paper_trail limit: 20, ignore: [ :visits_count ]

  belongs_to :forum_thread, touch: true
  belongs_to :user, optional: true
  belongs_to :last_editor, class_name: "User", optional: true

  default_scope { where(deleted: false) }

  validates :body, presence: true
  # Note: user is optional to allow for deleted users, but should be present at creation

  before_create :generate_public_id
  after_create :update_user_stats
  after_save :update_user_stats_if_deleted, if: -> { saved_change_to_deleted? }

  scope :search_by_body, ->(query) {
    return all if query.blank?
    if Rails.env.test?
      where("body LIKE ?", "%#{query}%")
    else
      where("MATCH(body) AGAINST(? IN BOOLEAN MODE)", "#{query}*")
    end
  }

  after_save :soft_delete_empty_thread, if: -> { saved_change_to_deleted? && deleted? }
  after_update :orphan_removed_images, if: :saved_change_to_body?
  after_update :orphan_deleted_post_images, if: -> { saved_change_to_deleted? && deleted? }

  def page(per_page = 20)
    position = forum_thread.ordered_posts.where("created_at <= ?", created_at).count
    (position.to_f / per_page).ceil
  end

  def user_post_count
    user&.forum_posts&.count || 0
  end

  private

  def generate_public_id
    loop do
      self.public_id = SecureRandom.alphanumeric(8)
      break unless ForumPost.unscoped.exists?(public_id: public_id)
    end
  end

  def orphan_removed_images
    old_body, new_body = saved_change_to_body
    removed = ForumImage.signed_ids_in_body(old_body) - ForumImage.signed_ids_in_body(new_body)

    removed.each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id) rescue next
      next unless blob
      fi = ForumImage.joins(:image_attachment)
                     .find_by(active_storage_attachments: { blob_id: blob.id })
      fi&.mark_as_orphan! unless fi&.referenced_in_any_live_post?(exclude_post_id: id)
    end
  end

  def orphan_deleted_post_images
    ForumImage.signed_ids_in_body(body).each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id) rescue next
      next unless blob
      fi = ForumImage.joins(:image_attachment)
                     .find_by(active_storage_attachments: { blob_id: blob.id })
      fi&.mark_as_orphan! unless fi&.referenced_in_any_live_post?(exclude_post_id: id)
    end
  end

  def soft_delete_empty_thread
    return unless forum_thread

    if forum_thread.forum_posts.count == 0
      forum_thread.update(deleted: true)
    end
  end

  def update_user_stats
    user&.stat&.recalculate!
  end

  def update_user_stats_if_deleted
    update_user_stats if deleted?
  end
end
