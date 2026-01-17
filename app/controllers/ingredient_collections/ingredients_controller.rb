class IngredientCollections::IngredientsController < ApplicationController
  # API only, no views
  allow_unauthenticated_access only: [] # Must be logged in

  before_action :set_collection
  before_action :set_ingredient, only: [ :destroy ]

  # POST /ingredient_collections/:ingredient_collection_id/ingredients
  # Single: { ingredient_id: 1 }
  # Multiple: { ingredient_ids: [1, 2, 3] }
  def create
    ingredient_ids = params[:ingredient_ids] || [ params[:ingredient_id] ].compact

    if ingredient_ids.blank?
      return render json: {
        success: false,
        error: "No ingredient_id or ingredient_ids provided"
      }, status: :bad_request
    end

    added = []
    errors = []

    ingredient_ids.each do |ingredient_id|
      ingredient = Ingredient.find_by(id: ingredient_id)

      if ingredient.nil?
        errors << "Ingredient #{ingredient_id} not found"
        next
      end

      if @collection.ingredients.exists?(ingredient.id)
        errors << "Ingredient '#{ingredient.name}' already in collection"
        next
      end

      @collection.ingredients << ingredient
      added << ingredient
    end

    render json: {
      success: errors.empty?,
      added: added.map { |i| ingredient_json(i) },
      errors: errors.presence,
      collection: collection_json(@collection.reload)
    }, status: (errors.empty? ? :created : :unprocessable_content)
  end

  # DELETE /ingredient_collections/:ingredient_collection_id/ingredients/:id
  def destroy
    @collection.ingredients.delete(@ingredient)

    render json: {
      success: true,
      removed: ingredient_json(@ingredient),
      collection: collection_json(@collection.reload)
    }
  end

  # PUT /ingredient_collections/:ingredient_collection_id/ingredients
  # Replaces all ingredients in collection
  # Params: { ingredient_ids: [1, 2, 3] }
  def update
    ingredient_ids = Array(params[:ingredient_ids]).compact.uniq

    # Validate all ingredients exist before replacing
    ingredients = Ingredient.where(id: ingredient_ids)

    if ingredients.count != ingredient_ids.count
      missing = ingredient_ids - ingredients.pluck(:id)
      return render json: {
        success: false,
        error: "Ingredients not found: #{missing.join(', ')}"
      }, status: :unprocessable_content
    end

    @collection.ingredients = ingredients

    render json: {
      success: true,
      collection: collection_json(@collection.reload)
    }
  end

  private

  def set_collection
    @collection = Current.user.ingredient_collections.find_by(id: params[:ingredient_collection_id])

    if @collection.nil?
      render json: {
        success: false,
        error: "Collection not found"
      }, status: :not_found
    end
  end

  def set_ingredient
    @ingredient = @collection.ingredients.find_by(id: params[:id])

    if @ingredient.nil?
      render json: {
        success: false,
        error: "Ingredient not found in this collection"
      }, status: :not_found
    end
  end

  def collection_json(collection)
    {
      id: collection.id,
      name: collection.name,
      notes: collection.notes,
      is_default: collection.is_default,
      ingredient_count: collection.ingredients.count,
      doable_recipes_count: collection.doable_recipes.length,
      ingredients: collection.ingredients.map { |i| ingredient_json(i) },
      created_at: collection.created_at,
      updated_at: collection.updated_at
    }
  end

  def ingredient_json(ingredient)
    {
      id: ingredient.id,
      name: ingredient.name
    }
  end
end
