class ForumThreadForm
  include ActiveModel::Model
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :forum_thread, :post_content, :user, :forum_topic, :thread_title

  validates :thread_title, presence: true
  validates :post_content, presence: true

  def persisted?
    false
  end

  def save
    if valid?
      persist!
      @forum_thread
    else
      false
    end
  end

  private

  def persist!
    @forum_thread = ForumThread.new(
      user_id: self.user.id,
      forum_topic_id: self.forum_topic.id,
      title: self.thread_title
    )
    @forum_post = ForumPost.new(
      user_id: self.user.id,
      content: self.post_content
    )
    @forum_thread.forum_posts << @forum_post
    @forum_thread.save
  end

end