class Recipe < ApplicationRecord
  include Rateable
  acts_as_taggable_on :tags
  
  belongs_to :user
  belongs_to :updated_by, class_name: 'User', optional: true
  
  has_many :recipe_ingredients, -> { order(position: :asc) }, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_comments, dependent: :destroy
  
  validates :title, presence: true

  def to_param
    slug
  end
end
