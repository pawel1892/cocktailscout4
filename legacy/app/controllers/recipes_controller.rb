class RecipesController < ApplicationController
  load_and_authorize_resource :find_by => :slug

  helper_method :sort_column, :sort_direction

  before_action :form_variables, only: [:index, :list]

  add_breadcrumb "Rezepte", :recipes_path

  def index
    @recipes = Recipe.all
    @filter = []

    if params.has_key?(:tag) and params[:tag].length > 0
      tag = ActsAsTaggableOn::Tag.find_by_slug(params[:tag])
      if tag.present?
        @recipes = @recipes.tagged_with(tag)
        @filter << 'Tag: '+ tag.name
      end
    end

    if (params.has_key?(:ingredient) and params[:ingredient].length > 0)
      ingredient = Ingredient.find_by_slug(params[:ingredient])
      if ingredient.present?
        @recipes = @recipes.contains_ingredient(ingredient.slug)
        @filter << 'Zutat ' + ingredient.name
      end
    end

    if (params.has_key?(:search))
      @recipes = @recipes.name_like(params[:search])
      @filter << 'Name: ' + params[:search] if params[:search].present?
    end

    if (params.has_key?(:ingredient_search))
      @recipes = @recipes.where(:id => session[:ingredient_search_result_recipes])
      @filter << 'Zutatensuche aktiv'
    end

    if (params.has_key?(:rating) && params[:rating].to_i > 0)
      @recipes = @recipes.minimum_rating(params[:rating])
      @filter << 'Bewertung: ' + params[:rating]
    end

    if (params.has_key?(:non_alcoholic))
      @recipes = @recipes.non_alcoholic
      @filter << 'alkoholfrei'
    end

    # pagination
    @recipes = @recipes.page(params[:page]).per(50)

    #sorting
    if (sort_column == 'rating')
      @recipes = @recipes.order_by_best_rated(sort_direction)
    elsif (sort_column == 'user')
      @recipes = @recipes.joins(:user).order("users.login #{sort_direction}")
    else
      @recipes = @recipes.order(sort_column + " " + sort_direction)
    end

  end

  def show
    @recipe = Recipe.friendly.find(params[:id])

    add_breadcrumb @recipe.name

    @recipe_images = RecipeImage.where(recipe_id: @recipe.id).approved.order('RAND()')

    @tags = @recipe.tag_counts

    @recipe_comments = @recipe.recipe_comments.order('created_at desc').limit(APP_CONFIG[:recipe_comments][:on_recipe_page])
    @count_all_recipe_comments = @recipe.recipe_comments.count

    @is_favorite = false
    if current_user
      @is_favorite = @recipe.is_favorite?(current_user)
    end

    if can? :create, RecipeComment
      @recipe_comment = RecipeComment.new
      if params.has_key?(:recipe_comment)
        @recipe_comment.user_id = current_user.id
        @recipe_comment.recipe_id = @recipe.id
        @recipe_comment.comment = params[:recipe_comment][:comment]
        @recipe_comment.ip = request.remote_ip

        if @recipe_comment.save
          redirect_to recipe_path(@recipe), notice: "Danke! Kommentar gespeichert."
        end
      end
    end

    Visit.track(@recipe, current_user)
  end

  def tag_cloud
    @tags = Recipe.tag_counts.order(:name)
    @levels = (1 .. 10).map { |i| "level-#{i}" }
  end

  def update_tags
    @recipe = Recipe.friendly.find(params[:recipe_id])
    @recipe.tag_list = params[:recipe][:tag_list]
    if @recipe.save
      flash[:success] = t 'recipes.messages.tags_saved'
      redirect_to recipe_path(@recipe)
    else
      flash[:error] = t 'recipes.messages.errors.save_tags'
      redirect_to recipe_path(@recipe)
    end
  end

  def tag
    tag = ActsAsTaggableOn::Tag.find_by_slug(params[:tag_slug])
    redirect_to recipes_path(:tag => tag)
  end

  def new
    @recipe = Recipe.new
  end

  def create
    @recipe = Recipe.new(recipe_params.merge(user: current_user))
    @recipe.description.gsub!("\n", '<br />')
    if @recipe.save
      redirect_to recipe_path(@recipe)
    else
      render :new
    end
  end

  def edit
    @recipe = Recipe.friendly.find(params[:id])
    @recipe.description.to_s.gsub!('<br />', "\n")
  end

  def update
    @recipe = Recipe.friendly.find(params[:id])
    if @recipe.update_attributes(recipe_params)
      @recipe.update_attribute(:description, @recipe.description.gsub("\n", '<br />'))
      redirect_to recipe_path(@recipe)
    else
      render :new
    end
  end

  def top_lists
    tags = [
        {tag: 'wodka', name: 'Wodka-Drinks'},
        {tag: 'gin', name: 'Gin-Drinks'},
        {tag: 'tequila', name: 'Tequila-Drinks'},
        {tag: 'whiskey', name: 'Whiskey-Drinks'},
        {tag: 'campari', name: 'Campari-Drinks'},
        {tag: 'sekt', name: 'Sekt-Drinks'},
        {tag: 'rum', name: 'Rum-Drinks'},
        {tag: 'erfrischend', name: 'erfrischend'},
        {tag: 'fruchtig', name: 'fruchtig'},
        {tag: 'herb', name: 'herb'},
        {tag: 'sauer', name: 'sauer'},
        {tag: 'süß', name: 'süß'},
        {tag: 'tropisch', name: 'tropisch'},
        {tag: 'Shooter', name: 'Shooter'},
        {tag: 'alkoholfrei', name: 'Alkoholfrei'}
    ]
    @lists = []
    tags.each do |list|
      @lists << {recipes: Recipe.toplist(list[:tag]).limit(10), name: list[:name]}
    end

  end

  private

    def recipe_params
      params.require(:recipe).permit(
          :name,
          :description,
          :recipe_ingredients_attributes => [
            :ingredient_id,
            :cl_amount,
            :description,
            :id,
            :"_destroy"
          ]
      )
    end

    def sort_column
      %w(name alcoholic_content rating user created_at).include?(params[:sort]) ? params[:sort] : "created_at"
    end

    def sort_direction
      %w(asc desc).include?(params[:direction]) ? params[:direction] : "desc"
    end

    def form_variables
      @tags = Recipe.tag_counts.order('name')
      @ingredients = Ingredient.order('name')
      @ingredient_search_selected_ingredients = session[:ingredient_search_selected_ingredients] || []
    end

end