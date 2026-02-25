class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :favorites, dependent: :destroy

  has_many :recipes, dependent: :nullify
  has_many :recipe_comments, dependent: :nullify
  has_many :forum_threads, dependent: :nullify
  has_many :forum_posts, dependent: :nullify
  has_many :recipe_images, dependent: :nullify

  has_many :ratings, dependent: :destroy

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_one :user_stat, dependent: :destroy

  has_many :ingredient_collections, dependent: :destroy

  has_many :recipe_suggestions, dependent: :nullify
  has_many :reviewed_suggestions, class_name: "RecipeSuggestion", foreign_key: "reviewed_by_id", dependent: :nullify

  has_many :sent_private_messages, -> { where(deleted_by_sender: false) },
    class_name: "PrivateMessage", foreign_key: "sender_id", dependent: :destroy
  has_many :received_private_messages, -> { where(deleted_by_receiver: false) },
    class_name: "PrivateMessage", foreign_key: "receiver_id", dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip }

  scope :online, -> { where("last_active_at > ?", 5.minutes.ago) }

  def online?
    last_active_at? && last_active_at > 5.minutes.ago
  end

  before_create :generate_confirmation_token

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :unconfirmed_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :unconfirmed_email_available

  generates_token_for :email_change, expires_in: 2.hours do
    unconfirmed_email
  end

  delegate :rank, :points, to: :stat

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def confirmed?
    confirmed_at.present?
  end

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
    self.confirmation_sent_at = Time.current
  end

  def send_confirmation_email!
    generate_confirmation_token
    save!
    UserMailer.confirmation_instructions(self).deliver_later
  end

  def unconfirmed_email_available
    if unconfirmed_email.present? && User.where.not(id: id).exists?(email_address: unconfirmed_email)
      errors.add(:unconfirmed_email, "ist bereits vergeben")
    end
  end

  def stat
    user_stat || create_user_stat
  end

  def admin?
    role?("admin")
  end

  def forum_moderator?
    role?("forum_moderator")
  end

  def recipe_moderator?
    role?("recipe_moderator")
  end

  def image_moderator?
    role?("image_moderator")
  end

  def super_moderator?
    role?("super_moderator")
  end

  def moderator?
    admin? || forum_moderator? || recipe_moderator? || image_moderator? || super_moderator?
  end

  def can_moderate_forum?
    admin? || forum_moderator? || super_moderator?
  end

  def can_moderate_recipe?
    admin? || recipe_moderator? || super_moderator?
  end

  def can_moderate_image?
    admin? || image_moderator? || super_moderator?
  end

  def role?(role_name)
    roles.exists?(name: role_name)
  end

  def default_collection
    ingredient_collections.find_by(is_default: true) || ingredient_collections.first
  end

  def unread_messages_count
    PrivateMessage.unread_by_user(self).count
  end
end
