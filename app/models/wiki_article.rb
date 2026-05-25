class WikiArticle < ApplicationRecord
  has_paper_trail limit: 50

  belongs_to :user
  belongs_to :last_editor, class_name: "User", optional: true

  has_one_attached :cover_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 320, 320 ]
    attachable.variant :hero,  resize_to_limit: [ 1200, 800 ]
  end

  has_many :ingredient_wiki_articles, dependent: :destroy
  has_many :ingredients, through: :ingredient_wiki_articles

  has_many :wiki_article_collaborators, dependent: :destroy
  has_many :collaborators, through: :wiki_article_collaborators, class_name: "User", source: :user

  validates :title, presence: true
  validates :body, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }
  scope :featured_articles, -> { where(featured: true).order(:featured_position) }

  scope :search, ->(query) {
    return none if query.blank?
    if Rails.env.test?
      where("title LIKE ? OR body LIKE ?", "%#{query}%", "%#{query}%")
    else
      where("MATCH(title, body) AGAINST(? IN BOOLEAN MODE)", "#{query}*")
    end
  }

  def to_param
    slug
  end

  def whodunnit_suggestions
    editor_ids = versions.pluck(:whodunnit).compact.uniq.map(&:to_i)
    editor_ids -= [ user_id ]
    editor_ids -= collaborator_ids
    editor_ids.any? ? User.where(id: editor_ids) : User.none
  end

  def linked_recipes
    return Recipe.none if ingredients.empty?
    Recipe.visible.joins(:recipe_ingredients)
      .where(recipe_ingredients: { ingredient_id: ingredient_ids })
      .distinct
      .order(average_rating: :desc, title: :asc)
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
