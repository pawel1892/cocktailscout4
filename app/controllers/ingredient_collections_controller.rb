class IngredientCollectionsController < ApplicationController
  # API only, no views
  allow_unauthenticated_access only: [] # Must be logged in

  before_action :set_collection, only: [ :show, :update, :destroy ]

  # GET /ingredient_collections
  def index
    collections = Current.user.ingredient_collections
      .includes(:ingredients)
      .order(is_default: :desc, created_at: :asc)

    render json: {
      success: true,
      collections: collections.map { |c| collection_json(c) }
    }
  end

  # GET /ingredient_collections/:id
  def show
    render json: {
      success: true,
      collection: collection_json(@collection, include_ingredients: true)
    }
  end

  # POST /ingredient_collections
  # Params: { name: string, notes: string (optional), is_default: boolean (optional) }
  def create
    collection = Current.user.ingredient_collections.build(collection_params)

    if collection.save
      render json: {
        success: true,
        collection: collection_json(collection)
      }, status: :created
    else
      render json: {
        success: false,
        errors: collection.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /ingredient_collections/:id
  # Params: { name: string, notes: string, is_default: boolean }
  def update
    if @collection.update(collection_params)
      render json: {
        success: true,
        collection: collection_json(@collection)
      }
    else
      render json: {
        success: false,
        errors: @collection.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  # DELETE /ingredient_collections/:id
  def destroy
    @collection.destroy
    render json: { success: true }
  end

  private

  def set_collection
    @collection = Current.user.ingredient_collections.find_by(id: params[:id])

    if @collection.nil?
      render json: {
        success: false,
        error: "Collection not found"
      }, status: :not_found
    end
  end

  def collection_params
    params.permit(:name, :notes, :is_default)
  end

  def collection_json(collection, include_ingredients: false)
    json = {
      id: collection.id,
      name: collection.name,
      notes: collection.notes,
      is_default: collection.is_default,
      ingredient_count: collection.ingredients.count,
      created_at: collection.created_at,
      updated_at: collection.updated_at
    }

    if include_ingredients
      json[:ingredients] = collection.ingredients.map { |i| ingredient_json(i) }
    end

    json
  end

  def ingredient_json(ingredient)
    {
      id: ingredient.id,
      name: ingredient.name
    }
  end
end
