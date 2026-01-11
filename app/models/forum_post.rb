class ForumPost < ApplicationRecord
  belongs_to :forum_thread
  belongs_to :user, optional: true

  validates :body, presence: true
  # Note: user is optional to allow for deleted users, but should be present at creation

  def page(per_page = 20)
    position = forum_thread.ordered_posts.where("created_at <= ?", created_at).count
    (position.to_f / per_page).ceil
  end

  def user_post_count
    user&.forum_posts&.count || 0
  end
end
