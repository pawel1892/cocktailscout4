class ForumImage < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_FILE_SIZE = 10.megabytes

  validates :image, presence: true
  validate :image_content_type_and_size, if: -> { image.attached? }

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
