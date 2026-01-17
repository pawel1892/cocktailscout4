class CollectionIngredient < ApplicationRecord
  belongs_to :ingredient_collection
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :ingredient_collection_id }
end
