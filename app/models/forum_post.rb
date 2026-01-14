class ForumPost < ApplicationRecord
  belongs_to :forum_thread, touch: true
  belongs_to :user, optional: true
  belongs_to :last_editor, class_name: "User", optional: true

  default_scope { where(deleted: false) }

  validates :body, presence: true
  # Note: user is optional to allow for deleted users, but should be present at creation

  after_save :soft_delete_empty_thread, if: -> { saved_change_to_deleted? && deleted? }

  def page(per_page = 20)
    position = forum_thread.ordered_posts.where("created_at <= ?", created_at).count
    (position.to_f / per_page).ceil
  end

  def user_post_count
    user&.forum_posts&.count || 0
  end

  private

  def soft_delete_empty_thread
    if forum_thread.forum_posts.count == 0
      forum_thread.update(deleted: true)
    end
  end
end
