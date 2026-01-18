class PrivateMessage < ApplicationRecord
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :receiver, class_name: "User", optional: true

  validates :body, presence: true
  validates :subject, presence: true

  scope :not_deleted_by_receiver, -> { where(deleted_by_receiver: false) }
  scope :not_deleted_by_sender, -> { where(deleted_by_sender: false) }
  scope :for_user, ->(user) {
    where("(receiver_id = ? AND deleted_by_receiver = false) OR (sender_id = ? AND deleted_by_sender = false)", user.id, user.id)
  }
end
