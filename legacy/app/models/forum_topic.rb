class ForumTopic < ActiveRecord::Base
  include FriendlyId

  has_paper_trail

  friendly_id :name, use: :slugged

  has_many :forum_threads

  validates_presence_of :name
  validates_presence_of :description

  scope :unread_by, -> (user) {
    forum_threads = ForumThread.arel_table
    visits = Visit.arel_table

    ForumTopic.where(
        Visit.where(
            visits[:visitable_id].eq(forum_threads[:id])
                .and(visits[:visitable_type].eq(ForumThread.name))
                .and(visits[:user_id].eq(user.id))
                .and(visits[:last_visit_time].gt(forum_threads[:last_post_created_cache]))
                .and(forum_threads[:last_post_created_cache].gt(1.week.ago))
        ).exists.not.and(
            forum_threads[:last_post_created_cache].gt(1.week.ago)
        )
    ).joins(
        ForumTopic.arel_table.join(ForumThread.arel_table).on(
            ForumTopic.arel_table[:id].eq(ForumThread.arel_table[:forum_topic_id])
        ).join_sources
    )
  }

  def post_count
    self.post_count_cache
  end

  def thread_count
    self.thread_count_cache
  end

  def last_post
    last_post_id = self.last_post_id_cache
    if last_post_id
      begin
        return ForumPost.find(last_post_id)
      rescue ActiveRecord::RecordNotFound
        return nil
      end
    else
      return nil
    end
  end

  def update_caches
    self.post_count_cache = calculate_post_count
    self.thread_count_cache = self.forum_threads.count
    if self.calculate_last_post
      self.last_post_id_cache = self.calculate_last_post.id
    end
  end

  def update_caches!
    self.update_caches
    self.save
  end

  protected

    def calculate_post_count
      self.forum_threads.joins(:forum_posts).count
    end

    def calculate_last_post
      ForumPost.joins(:forum_thread => :forum_topic).where('forum_topics.id = ?', self.id).order('forum_posts.created_at DESC, id DESC').first
    end

  end
