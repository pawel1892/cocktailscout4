class IngredientWikiArticle < ApplicationRecord
  belongs_to :ingredient
  belongs_to :wiki_article
end
