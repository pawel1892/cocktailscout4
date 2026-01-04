class Recipe < ActiveRecord::Base
  include FriendlyId
  include Visitable
  has_many :visits, :as => :visitable

  friendly_id :name, use: :slugged

  has_paper_trail meta: { tag_list: :tag_list }

  has_many :recipe_ingredients
  has_many :ingredients, :through => :recipe_ingredients

  has_many :user_recipes

  has_many :recipe_comments
  belongs_to :user
  belongs_to :last_edit_user, :class_name => 'User', optional: true

  #has_many :users, :through => :recipe_comments

  has_many :recipe_images

  accepts_nested_attributes_for :recipe_ingredients, :allow_destroy => true

  letsrate_rateable "taste"

  has_one :rate_average_taste, -> {where dimension: 'taste'}, :as => :cacheable, :class_name => "RatingCache",
          :dependent => :destroy

  acts_as_taggable

  scope :order_by_best_rated, lambda {|direction = 'DESC'| joins("LEFT JOIN `rating_caches` ON `rating_caches`.`cacheable_id` = `recipes`.`id` AND `rating_caches`.`dimension` = 'taste' AND `rating_caches`.`cacheable_type` = 'Recipe'").order("rating_caches.avg #{direction}")}
  scope :order_by_user, lambda {|direction = 'DESC'| joins("LEFT JOIN `rating_caches` ON `rating_caches`.`cacheable_id` = `recipes`.`id` AND `rating_caches`.`dimension` = 'taste' AND `rating_caches`.`cacheable_type` = 'Recipe'").order("rating_caches.avg #{direction}")}

  scope :contains_ingredient, lambda{ |ingredient_slug| joins(:ingredients).where('ingredients.slug = ?', ingredient_slug) }

  scope :user_favorites, lambda{ |user_id| joins(:user_recipes).where('user_recipes.user_id = ? AND user_recipes.dimension = ?', user_id, 'favorite')}

  scope :name_like, lambda { |search| where('recipes.name LIKE ?', "%#{search}%") }

  scope :minimum_rating, lambda { |rating| joins(:rate_average_taste).where('rating_caches.avg >= ?', rating)}

  scope :non_alcoholic, lambda { where(alcoholic_content: 0)}

  scope :toplist, lambda { |tag| tagged_with(tag).order_by_best_rated }

  validates_presence_of :name, :description
  # todo why this was here? and why did the code worked before with recipes without last_edit_user
  # validates_associated :user, :last_edit_user, :presence => true
  validate :validate_recipe_ingredient_count


  after_initialize :default_values

  after_create :recalculate_user_points

  before_save :refresh_cl_amount_and_alcoholic_content_cache

  class << self
    def mixable_from_ingredients (ingredientd_id_array)
      recipes = Recipe.arel_table
      recipe_ingredients = RecipeIngredient.arel_table
      r = Recipe.where(
          (RecipeIngredient.where(recipe_ingredients[:ingredient_id].not_in(ingredientd_id_array).and(recipe_ingredients[:recipe_id].eq(recipes[:id]))).exists.not).and(RecipeIngredient.where(recipe_ingredients[:ingredient_id].gt(0).and(recipe_ingredients[:recipe_id].eq(recipes[:id]))).exists)
      )
    end
  end

  def refresh_cl_amount_and_alcoholic_content_cache
    unless is_cl_amount_and_alcoholic_content_calculable?
      self.cl_amount = nil
      self.alcoholic_content = nil
      return false
    end

    cl_amount=0
    alcoholic_content=0
    self.recipe_ingredients.each do |ri|
      cl_amount += ri.cl_amount
      alcoholic_content += ri.cl_amount * ri.ingredient.alcoholic_content
    end

    if cl_amount==0
      self.cl_amount = nil
      self.alcoholic_content = nil
      return false
    end

    self.cl_amount = cl_amount
    self.alcoholic_content = alcoholic_content / cl_amount
  end

  def is_favorite?(user)
    if UserRecipe.where(:recipe_id => self.id, :dimension => 'favorite', :user_id => user.id).count > 0
      return true
    end

    return false
  end

  def rating
    self.rate_average_taste.avg rescue 0
  end

  def rating_count
    self.rate_average_taste.qty rescue 0
  end

  def rating_for_user(user)
    Rate.find_by_rater_id_and_rateable_id_and_dimension(user.id, self.id, 'taste').stars rescue nil
  end
  
  private

    # no values (alcoholic_content of ingredient and cl amount) are missing
    def is_cl_amount_and_alcoholic_content_calculable?
      self.recipe_ingredients.each do |recipe_ingredient|
        if recipe_ingredient.cl_amount.nil?
          return false
        end

        unless recipe_ingredient.ingredient
          return false
        end

        if recipe_ingredient.ingredient.alcoholic_content.nil?
          return false
        end
      end

      return true
    end

    def default_values
      self.self_created ||= false
    rescue ActiveModel::MissingAttributeError
      # this should only happen on Model.exists?() call. It can be safely ignored.
    end

    def recalculate_user_points
      self.user.user_rank.recalculate_points!
    end

    def validate_recipe_ingredient_count
      if recipe_ingredients.reject(&:marked_for_destruction?).size < 2
        errors.add :base, I18n.t('activemodel.errors.models.recipe.min_ingredients_req')
      end
    end

end
