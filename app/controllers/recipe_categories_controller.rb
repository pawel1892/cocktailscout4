class RecipeCategoriesController < ApplicationController
  allow_unauthenticated_access

  def index
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb "Rezept-Kategorien"
    @tags = Recipe.visible_tags.order(:name)
  end
end
