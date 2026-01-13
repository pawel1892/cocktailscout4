class ForumTopic < ApplicationRecord
  has_many :forum_threads

  validates :name, presence: true
  validates :description, presence: true

  def to_param
    slug
  end

  scope :unread_by, ->(user) {
    forum_threads = ForumThread.arel_table
    visits = Visit.arel_table

    visit_subquery = Visit.where(
      visits[:visitable_id].eq(forum_threads[:id])
        .and(visits[:visitable_type].eq(ForumThread.name))
        .and(visits[:user_id].eq(user.id))
        .and(visits[:last_visited_at].gt(forum_threads[:updated_at]))
    ).arel.exists

    ForumTopic.joins(:forum_threads)
      .where(visit_subquery.not)
      .where(forum_threads[:updated_at].gt(1.week.ago))
      .distinct
  }

  def post_count
    forum_threads.joins(:forum_posts).count
  end

  def thread_count
    forum_threads.count
  end

  def last_post
    ForumPost.joins(forum_thread: :forum_topic)
             .where(forum_topics: { id: id })
             .order("forum_posts.created_at DESC, forum_posts.id DESC")
             .first
  end
end
