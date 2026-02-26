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

  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :by_recipe_name, ->(q) { joins(:recipe).where("recipes.title LIKE ?", "%#{q}%") if q.present? }
  scope :recent,          -> { order(created_at: :desc) }
  scope :not_soft_deleted, -> { where(deleted_at: nil) }
  scope :soft_deleted,     -> { where.not(deleted_at: nil) }

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_FILE_SIZE         = 10.megabytes

  validates :image, presence: true
  validate :image_content_type_and_size, if: -> { image.attached? }

  def rotate_image!(degrees)
    original_filename     = image.blob.filename.to_s
    original_content_type = image.blob.content_type

    image.blob.open do |temp_file|
      processor = Rails.application.config.active_storage.variant_processor == :vips ?
        ImageProcessing::Vips : ImageProcessing::MiniMagick

      processed = processor
        .source(temp_file)
        .rotate(degrees)
        .call

      image.purge

      image.attach(
        io:           processed,
        filename:     original_filename,
        content_type: original_content_type
      )
    end

    if approved?
      image.variant(:thumb).processed
      image.variant(:medium).processed
    end
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def soft_deleted?
    deleted_at.present?
  end

  def approve!(moderator)
    update!(state: "approved", moderated_by: moderator, moderated_at: Time.current)
    image.variant(:thumb).processed
    image.variant(:medium).processed
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
