class ForumPost < ActiveRecord::Base
  include Csbml

  has_paper_trail

  belongs_to :forum_thread
  belongs_to :user

  default_scope { where(:deleted => false) }

  validates :user, presence: true
  validates_presence_of :content

  after_commit :update_caches!

  after_destroy :delete_empty_thread

  def delete
    self.deleted = true
    self.save
  end

  def page
    position = self.forum_thread.ordered_posts.where('created_at <= ?', self.created_at).count
    (position.to_f/APP_CONFIG[:forum_posts][:per_page]).ceil
  end

  def update_caches!
    thread = self.forum_thread
    thread.update_caches! rescue return nil
    thread.forum_topic.update_caches!
  end

  protected

  def delete_empty_thread
    thread = self.forum_thread
    if thread.forum_posts.count == 0
      thread.delete
    end
  end

end
