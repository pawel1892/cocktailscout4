class ForumThread < ApplicationRecord
  belongs_to :forum_topic
  belongs_to :user, optional: true

  has_many :forum_posts, dependent: :destroy
end
