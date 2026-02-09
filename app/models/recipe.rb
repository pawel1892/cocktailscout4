class Recipe < ApplicationRecord
  include Favoritable
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
  scope :by_collection, ->(collection_id) {
    if collection_id.present?
      collection = IngredientCollection.find_by(id: collection_id)
      if collection
        where(id: collection.doable_recipes.select(:id))
      else
        none
      end
    end
  }
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

  def scale(factor)
    recipe_ingredients.map { |ri| ri.scale(factor) }
  end

  def total_volume_in_ml
    recipe_ingredients.sum { |ri| ri.amount_in_ml || 0 }
  end

  # Calculate total alcohol volume in ml
  def alcohol_volume_in_ml
    recipe_ingredients.sum do |ri|
      next 0 unless ri.amount_in_ml && ri.ingredient.alcoholic_content
      ri.amount_in_ml * (ri.ingredient.alcoholic_content / 100.0)
    end
  end

  # Calculate alcohol content (ABV) as percentage
  def calculate_alcohol_content
    total = total_volume_in_ml
    return 0.0 if total.zero?

    (alcohol_volume_in_ml / total * 100.0).round(1)
  end

  # Update computed fields in database
  def update_computed_fields!
    update_columns(
      total_volume: total_volume_in_ml.round(1),
      alcohol_content: calculate_alcohol_content
    )
  end
end
