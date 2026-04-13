class WikiArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  before_action :set_article, only: %i[show edit update destroy]
  before_action :authorize_write!, only: %i[new create edit update]
  before_action :authorize_delete!, only: %i[destroy]

  def index
    add_breadcrumb "Wiki"
    @pagy, @wiki_articles = pagy(WikiArticle.published.order(title: :asc), limit: 30)
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
    @wiki_article = WikiArticle.new(article_params)
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
  end

  def update
    if @wiki_article.update(article_params.merge(last_editor: Current.user))
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
    @wiki_article = WikiArticle.includes(:ingredients, :user, :last_editor).find_by!(slug: params[:slug])
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
    params.require(:wiki_article).permit(:title, :body, :published, ingredient_ids: [])
  end
end
