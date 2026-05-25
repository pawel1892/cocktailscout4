class WikiArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[index show search]

  before_action :set_article, only: %i[show edit update destroy]
  before_action :authorize_write!, only: %i[new create edit update drafts]
  before_action :authorize_delete!, only: %i[destroy]

  def index
    add_breadcrumb "Wiki", wiki_dashboard_path
    add_breadcrumb "Alle Artikel"
    @pagy, @wiki_articles = pagy(WikiArticle.published.includes(:ingredients).order(title: :asc), limit: 50)
  end

  def search
    @query = params[:q].to_s.strip
    respond_to do |format|
      format.html do
        add_breadcrumb "Wiki", wiki_dashboard_path
        add_breadcrumb "Suche"
        if @query.present?
          @pagy, @wiki_articles = pagy(
            WikiArticle.published.search(@query).includes(:ingredients).order(title: :asc),
            limit: 20
          )
        else
          @pagy, @wiki_articles = pagy(WikiArticle.none)
        end
      end
      format.json do
        articles = @query.length >= 2 ? WikiArticle.published.search(@query).order(title: :asc).limit(10) : []
        render json: { wiki_articles: articles.map { |a| { slug: a.slug, title: a.title } } }
      end
    end
  end

  def drafts
    add_breadcrumb "Wiki", wiki_dashboard_path
    add_breadcrumb "Entwürfe"
    @draft_articles = WikiArticle.unpublished.includes(:ingredients).order(title: :asc)
  end

  def show
    add_breadcrumb "Wiki", wiki_articles_path
    add_breadcrumb @wiki_article.title

    unless @wiki_article.published? || Current.user&.can_edit_wiki?
      redirect_to wiki_articles_path, alert: "Artikel nicht gefunden." and return
    end

    @linked_recipes = @wiki_article.linked_recipes
  end

  def new
    add_breadcrumb "Wiki", wiki_articles_path
    add_breadcrumb "Neuer Artikel"
    @wiki_article = WikiArticle.new
  end

  def create
    p = article_params
    p.delete("remove_cover_image") || p.delete(:remove_cover_image)
    @wiki_article = WikiArticle.new(p)
    @wiki_article.user = Current.user

    if @wiki_article.save
      redirect_to wiki_article_path(@wiki_article), notice: "Artikel erfolgreich erstellt."
    else
      add_breadcrumb "Wiki", wiki_articles_path
      add_breadcrumb "Neuer Artikel"
      render :new, status: :unprocessable_content
    end
  end

  def edit
    add_breadcrumb "Wiki", wiki_articles_path
    add_breadcrumb @wiki_article.title, wiki_article_path(@wiki_article)
    add_breadcrumb "Bearbeiten"
    @whodunnit_suggestions = @wiki_article.whodunnit_suggestions
  end

  def update
    p = article_params
    remove = p.delete("remove_cover_image") || p.delete(:remove_cover_image)
    @wiki_article.cover_image.purge if remove == "1"
    if @wiki_article.update(p.merge(last_editor: Current.user))
      redirect_to wiki_article_path(@wiki_article), notice: "Artikel aktualisiert."
    else
      add_breadcrumb "Wiki", wiki_articles_path
      add_breadcrumb @wiki_article.title, wiki_article_path(@wiki_article)
      add_breadcrumb "Bearbeiten"
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @wiki_article.destroy
    redirect_to wiki_articles_path, notice: "Artikel gelöscht."
  end

  private

  def set_article
    @wiki_article = WikiArticle.includes(:ingredients, :collaborators, :user, :last_editor, :versions, cover_image_attachment: :blob).find_by!(slug: params[:slug])
  end

  def authorize_write!
    unless Current.user&.can_edit_wiki?
      redirect_to wiki_articles_path, alert: "Du hast keine Berechtigung, Wiki-Artikel zu bearbeiten."
    end
  end

  def authorize_delete!
    unless Current.user&.admin? || Current.user&.super_moderator?
      redirect_to wiki_articles_path, alert: "Du hast keine Berechtigung, Wiki-Artikel zu löschen."
    end
  end

  def article_params
    params.require(:wiki_article).permit(:title, :body, :published, :featured, :featured_position, :cover_image, :remove_cover_image, ingredient_ids: [], collaborator_ids: []).tap do |p|
      p[:ingredient_ids]&.reject!(&:blank?)
      p[:collaborator_ids]&.reject!(&:blank?)
    end
  end
end
