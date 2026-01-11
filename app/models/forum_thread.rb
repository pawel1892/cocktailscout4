class ForumThread < ApplicationRecord
  include Visitable
  belongs_to :forum_topic
  belongs_to :user, optional: true

  has_many :forum_posts, dependent: :destroy

  default_scope { where(deleted: false) }

  validates :title, presence: true
  validates :forum_topic, presence: true
  # Note: user is optional to allow for deleted users, but should be present at creation

  scope :last_active_threads, -> { order(updated_at: :desc) }

  def views
    visits_count || total_visits
  end

  def count_posts
    forum_posts.count
  end

  def ordered_posts
    forum_posts.order(created_at: :asc)
  end

  def ordered_posts_by_page(page = 1, per_page = 20)
    ordered_posts.offset((page.to_i - 1) * per_page).limit(per_page)
  end

  def last_post
    forum_posts.order("forum_posts.created_at DESC, id DESC").first
  end

  def read_by?(user)
    return false unless last_visited_at_by(user)
    return false unless last_post

    last_visited_at_by(user) >= last_post.created_at
  end

  def first_unread_post(user)
    last_visit_time = last_visited_at_by(user)
    if last_visit_time
      ordered_posts.where("created_at > ?", last_visit_time).first
    else
      ordered_posts.first
    end
  end

  def last_post_user
    last_post&.user
  end

  def last_post_created_at
    last_post&.created_at
  end
end
