class PrivateMessage < ActiveRecord::Base
  validates_presence_of :subject
  validates_presence_of :message

  belongs_to :receiver, class_name: 'User', foreign_key: 'receiver_id'
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'

  scope :unread, -> { where(read: false, deleted_by_receiver: false) }
  scope :unread_by_user, -> (user){ unread.where(receiver_id: user.id) }

  def self.report_to_forum_mods(sender, object_path)
    subject = 'Meldung Forenbeitrag'
    message = 'Folgender Beitrag wurde gemeldet: ' + object_path
    User.forum_mods.each do |mod|
      create(sender: sender, receiver: mod, subject: subject, message: message)
    end
    true
  end

end
