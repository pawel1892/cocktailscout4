class Ingredient < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :alcoholic_content, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
