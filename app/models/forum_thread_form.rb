class ForumThreadForm
  include ActiveModel::Model

  attr_accessor :forum_thread, :post_content, :user, :forum_topic, :thread_title

  validates :thread_title, presence: true
  validates :post_content, presence: true
  validates :user, presence: true
  validates :forum_topic, presence: true

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @forum_thread = ForumThread.new(
        user: user,
        forum_topic: forum_topic,
        title: thread_title
      )

      # We must save thread first? No, Rails usually handles this if we build associations.
      # But legacy did explicit save.
      # Let's try building post on thread.

      @forum_thread.forum_posts.build(
        user: user,
        body: post_content
      )

      @forum_thread.save!
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
