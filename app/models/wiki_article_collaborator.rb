class WikiArticleCollaborator < ApplicationRecord
  belongs_to :wiki_article
  belongs_to :user
end
