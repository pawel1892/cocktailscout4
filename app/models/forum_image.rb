class ForumImage < ApplicationRecord
  belongs_to :user, optional: true

  has_one_attached :image

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_FILE_SIZE = 10.megabytes

  BLOB_URL_PATTERN = %r{/rails/active_storage/blobs/(?:redirect|proxy)/([^/\s"']+)/}

  scope :marked_as_orphaned, -> { where.not(orphaned_at: nil) }
  scope :not_marked_as_orphaned, -> { where(orphaned_at: nil) }
  scope :pending_deletion, -> { where("orphaned_at < ?", 30.days.ago) }

  validates :image, presence: true
  validate :image_content_type_and_size, if: -> { image.attached? }

  def self.signed_ids_in_body(body)
    body.scan(BLOB_URL_PATTERN).flatten.to_set
  end

  def self.detect_orphans
    all_bodies = ForumPost.unscoped.where(deleted: false).pluck(:body).join("\n")
    referenced = signed_ids_in_body(all_bodies)
    includes(image_attachment: :blob).not_marked_as_orphaned.select do |fi|
      fi.image.attached? && !referenced.include?(fi.image.blob.signed_id)
    end
  end

  def referenced_in_any_live_post?(exclude_post_id: nil)
    return false unless image.attached?
    signed_id = image.blob.signed_id
    scope = ForumPost.unscoped.where(deleted: false)
    scope = scope.where.not(id: exclude_post_id) if exclude_post_id
    scope.where("body LIKE ?", "%#{signed_id}%").exists?
  end

  def mark_as_orphan!
    update!(orphaned_at: Time.current) if orphaned_at.nil?
  end

  def restore!
    update!(orphaned_at: nil)
  end

  def orphaned?
    orphaned_at.present?
  end

  private

  def image_content_type_and_size
    unless ALLOWED_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "muss ein JPEG, PNG, WebP oder GIF sein")
    end
    if image.blob.byte_size > MAX_FILE_SIZE
      errors.add(:image, "darf nicht größer als 10 MB sein")
    end
  end
end
