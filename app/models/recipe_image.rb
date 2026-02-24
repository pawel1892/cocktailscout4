class RecipeImage < ApplicationRecord
  belongs_to :recipe
  belongs_to :user
  belongs_to :moderated_by, class_name: "User", optional: true

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 100, 100 ]
    attachable.variant :medium, resize_to_limit: [ 500, 500 ]
    attachable.variant :large, resize_to_limit: [ 1200, 1200 ]
  end

  enum :state, { pending: "pending", approved: "approved", rejected: "rejected" }

  scope :recent, -> { order(created_at: :desc) }

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_FILE_SIZE         = 10.megabytes

  validates :image, presence: true
  validate :image_content_type_and_size, if: -> { image.attached? }

  def approve!(moderator)
    update!(state: "approved", moderated_by: moderator, moderated_at: Time.current)
  end

  def reject!(moderator, reason)
    update!(state: "rejected", moderated_by: moderator, moderated_at: Time.current,
            moderation_reason: reason)
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
