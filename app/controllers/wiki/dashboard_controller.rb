class Wiki::DashboardController < ApplicationController
  allow_unauthenticated_access only: [ :show ]
  # TEMP_WIKI_PROD_HIDE: Hide the wiki dashboard from production non-editors.
  prepend_before_action :require_visible_wiki!

  def show
    add_breadcrumb "Wiki"
    @featured_articles = WikiArticle.published.featured_articles
                           .includes(:ingredients, cover_image_attachment: :blob)
  end
end
