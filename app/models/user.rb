class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :recipe_comments, dependent: :nullify
  has_many :recipe_images, dependent: :destroy

  has_many :ratings, dependent: :destroy

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  normalizes :email_address, with: ->(e) { e.strip.downcase }

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
