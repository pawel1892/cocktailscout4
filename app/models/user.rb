class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :recipes, dependent: :nullify
  has_many :recipe_comments, dependent: :nullify
  has_many :recipe_images, dependent: :nullify

  has_many :ratings, dependent: :destroy

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_one :user_stat, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  delegate :rank, :points, to: :stat

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

  def role?(role_name)
    roles.exists?(name: role_name)
  end
end
