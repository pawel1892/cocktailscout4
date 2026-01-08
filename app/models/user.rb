class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :recipe_comments, dependent: :nullify
  has_many :recipe_images, dependent: :destroy

  has_many :ratings, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
