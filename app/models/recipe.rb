class Recipe < ApplicationRecord
  belongs_to :user
  belongs_to :updated_by, class_name: 'User', optional: true
  
  has_many :recipe_ingredients, -> { order(position: :asc) }, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  
  validates :title, presence: true

  def to_param
    slug
  end
end
