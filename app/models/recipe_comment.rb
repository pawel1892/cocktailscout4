class RecipeComment < ApplicationRecord
  include Reportable
  has_paper_trail limit: 10

  acts_as_taggable_on :comment_types

  belongs_to :user, optional: true
  belongs_to :recipe
  belongs_to :last_editor, class_name: "User", optional: true
  belongs_to :parent, class_name: "RecipeComment", optional: true
  has_many :replies, class_name: "RecipeComment", foreign_key: :parent_id, dependent: :destroy
  has_many :comment_votes, dependent: :destroy

  scope :top_level, -> { where(parent_id: nil) }

  validates :body, presence: true, length: { maximum: 3000 }
  validate :parent_must_be_top_level

  after_create :update_user_stats
  after_destroy :update_user_stats

  private

  def parent_must_be_top_level
    if parent_id.present? && parent&.parent_id.present?
      errors.add(:parent, "must be a top-level comment (no nested replies)")
    end
  end

  def update_user_stats
    user&.stat&.recalculate!
  end
end
