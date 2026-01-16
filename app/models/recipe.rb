class Recipe < ApplicationRecord
  include Rateable
  include Visitable
  acts_as_taggable_on :tags

  belongs_to :user
  belongs_to :updated_by, class_name: "User", optional: true

  has_many :recipe_ingredients, -> { order(position: :asc) }, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_comments, dependent: :destroy
  has_many :recipe_images, dependent: :destroy
  has_many :approved_recipe_images, -> { approved }, class_name: "RecipeImage"

  has_many :ratings, as: :rateable, dependent: :destroy

  scope :by_min_rating, ->(rating) { where("average_rating >= ?", rating) if rating.present? }
  scope :by_ingredient, ->(ingredient_id) { joins(:ingredients).where(ingredients: { id: ingredient_id }) if ingredient_id.present? }
  scope :search_by_title, ->(query) {
    return all if query.blank?
    if Rails.env.test?
      where("title LIKE ?", "%#{query}%")
    else
      where("MATCH(title) AGAINST(? IN BOOLEAN MODE)", "#{query}*")
    end
  }

  validates :title, presence: true
  validates :slug, uniqueness: true, allow_blank: true

  def to_param
    slug
  end
end
