class ForumThread < ApplicationRecord
  include Visitable
  has_paper_trail limit: 10, ignore: [ :deleted, :visits_count ]

  belongs_to :forum_topic, touch: true
  belongs_to :user, optional: true

  has_many :forum_posts, dependent: :destroy

  default_scope { where(deleted: false) }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :forum_topic, presence: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :last_active_threads, -> { order(updated_at: :desc) }
  scope :search_by_title, ->(query) {
    return all if query.blank?
    if Rails.env.test?
      where("title LIKE ?", "%#{query}%")
    else
      where("MATCH(title) AGAINST(? IN BOOLEAN MODE)", "#{query}*")
    end
  }

  def to_param
    slug
  end

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

  def first_post
    forum_posts.order(created_at: :asc).first
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

  private

  def generate_slug
    base_slug = title.parameterize
    self.slug = base_slug

    # Simple conflict resolution
    count = 1
    while ForumThread.exists?(slug: self.slug)
      self.slug = "#{base_slug}-#{count}"
      count += 1
    end
  end
end
