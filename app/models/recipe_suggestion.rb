class RecipeSuggestion < ApplicationRecord
  has_paper_trail

  # Associations
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :published_recipe, class_name: "Recipe", optional: true
  has_many :recipe_suggestion_ingredients, -> { order(position: :asc) }, dependent: :destroy
  has_many :ingredients, through: :recipe_suggestion_ingredients

  # Enums
  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }, prefix: true

  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :status, presence: true

  # Scopes
  scope :pending_review, -> { where(status: "pending") }
  scope :reviewed, -> { where.not(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  # Instance methods
  def editable_by?(current_user)
    return false unless current_user
    return false unless user_id == current_user.id
    status_pending? || status_rejected?
  end

  def to_recipe_params
    {
      title: title,
      description: description,
      tag_list: tag_list,
      is_public: true,
      ingredients_data: recipe_suggestion_ingredients.map do |rsi|
        {
          ingredient_id: rsi.ingredient_id,
          ingredient_name: rsi.ingredient.name,
          unit_id: rsi.unit_id,
          amount: rsi.amount&.to_s,
          additional_info: rsi.additional_info,
          display_name: rsi.display_name,
          is_optional: rsi.is_optional,
          is_scalable: rsi.is_scalable,
          position: rsi.position
        }
      end
    }
  end
end
