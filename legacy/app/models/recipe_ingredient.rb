class RecipeIngredient < ActiveRecord::Base

  belongs_to :recipe
  belongs_to :ingredient

  validates :ingredient, presence: true
  validates :cl_amount, presence: true
  validates :description, presence: true
end
