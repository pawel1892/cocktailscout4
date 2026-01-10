class RecipeImage < ApplicationRecord
  belongs_to :recipe
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 100, 100 ]
    attachable.variant :medium, resize_to_limit: [ 500, 500 ]
    attachable.variant :large, resize_to_limit: [ 1200, 1200 ]
  end

  scope :approved, -> { where.not(approved_at: nil) }
  scope :pending, -> { where(approved_at: nil) }

  validates :image, presence: true
end
