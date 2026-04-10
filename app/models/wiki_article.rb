class WikiArticle < ApplicationRecord
  has_paper_trail limit: 50

  belongs_to :user
  belongs_to :last_editor, class_name: "User", optional: true
  belongs_to :ingredient, optional: true

  validates :title, presence: true
  validates :body, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(published: true) }

  def to_param
    slug
  end

  def linked_recipes
    return Recipe.none unless ingredient
    ingredient.recipes.visible.order(average_rating: :desc, title: :asc)
  end

  private

  def generate_slug
    base = title.parameterize
    candidate = base
    count = 1
    while WikiArticle.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{count}"
      count += 1
    end
    self.slug = candidate
  end
end
