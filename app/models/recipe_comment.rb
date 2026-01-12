class RecipeComment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :recipe

  validates :body, presence: true, length: { maximum: 3000 }
end
