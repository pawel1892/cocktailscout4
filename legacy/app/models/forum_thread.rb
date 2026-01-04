class ForumThread < ActiveRecord::Base
  include Visitable

  has_paper_trail

  #FIXME put this into the module
  has_many :visits, :as => :visitable

  belongs_to :forum_topic
  belongs_to :user
  has_many :forum_posts

  include FriendlyId
  friendly_id :title, use: :slugged

  validates :user, presence: true
  validates :forum_topic, presence: true
  validates_presence_of :title
  validate :validate_post_count

  before_save :update_caches

  scope :last_active_threads, -> { order('last_post_created_cache DESC') }

  def views
    self.visits_count
  end

  def count_posts
    self.post_count_cache
  end

  def ordered_posts
    self.forum_posts.order('created_at ASC')
  end

  def ordered_posts_by_page(page = 1)
    self.ordered_posts.page(page).per(APP_CONFIG[:forum_posts][:per_page])
  end

  def last_post
    self.forum_posts.order('forum_posts.created_at DESC, id DESC').first
  end

  def read_by?(user)
    unless self.last_visit_time_by(user)
      return false
    end

    if self.last_visit_time_by(user) >= last_post.created_at
      return true
    else
      return false
    end
  end

  def first_unread_post(user)
    last_visit_time = self.last_visit_time_by(user)
    if last_visit_time
      self.ordered_posts.where("created_at > '#{self.last_visit_time_by(user).to_s(:db)}'").first
    else
      self.ordered_posts.first
    end
  end

  def last_post_user
    last_post_user_id = self.last_post_user_id_cache
    if last_post_user_id
      begin
        return User.find(last_post_user_id)
      rescue ActiveRecord::RecordNotFound
        return nil
      end
    else
      return nil
    end
  end

  def update_caches
    self.post_count_cache = calculate_post_count
    if self.calculate_last_post
      self.last_post_created_cache = self.calculate_last_post.created_at
      self.last_post_user_id_cache = self.calculate_last_post.user_id
    end
  end

  def update_caches!
    self.update_caches
    self.save
  end

  protected

  def calculate_post_count
    self.forum_posts.count
  end

  def calculate_last_post
    self.forum_posts.order('forum_posts.created_at DESC, id DESC').first
  end

  def validate_post_count
    self.errors.add(:base, 'Threads should contain at least one post') if self.forum_posts.length < 1
  end
end
