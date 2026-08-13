class Wiki::DashboardController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    add_breadcrumb "Wiki"
    @featured_articles = WikiArticle.published.featured_articles
                           .includes(:ingredients, cover_image_attachment: :blob)
  end
end
