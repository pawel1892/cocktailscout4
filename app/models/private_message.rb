class PrivateMessage < ApplicationRecord
  include Reportable

  belongs_to :sender, class_name: "User", optional: true
  belongs_to :receiver, class_name: "User", optional: true

  validates :body, presence: true
  validates :subject, presence: true
  validates :receiver_id, presence: true

  scope :not_deleted_by_receiver, -> { where(deleted_by_receiver: false) }
  scope :not_deleted_by_sender, -> { where(deleted_by_sender: false) }
  scope :for_user, ->(user) {
    where("(receiver_id = ? AND deleted_by_receiver = false) OR (sender_id = ? AND deleted_by_sender = false)", user.id, user.id)
  }
  scope :received_by, ->(user) {
    where(receiver_id: user.id, deleted_by_receiver: false).order(created_at: :desc)
  }
  scope :sent_by, ->(user) {
    where(sender_id: user.id, deleted_by_sender: false).order(created_at: :desc)
  }
  scope :unread, -> { where(read: false) }
  scope :unread_by_user, ->(user) {
    where(receiver_id: user.id, read: false, deleted_by_receiver: false)
  }
end
