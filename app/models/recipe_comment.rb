class RecipeComment < ApplicationRecord
  include Reportable
  belongs_to :user, optional: true
  belongs_to :recipe
  belongs_to :last_editor, class_name: "User", optional: true

  validates :body, presence: true, length: { maximum: 3000 }

  after_create :update_user_stats
  after_destroy :update_user_stats

  private

  def update_user_stats
    user&.stat&.recalculate!
  end
end
