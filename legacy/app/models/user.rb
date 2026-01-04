class User < ActiveRecord::Base

  letsrate_rater

  acts_as_tagger

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_roles
  has_many :roles, :through => :user_roles

  has_many :blog_entries

  has_many :recipe_comments
  has_many :recipes
  #has_many :recipes, :through => :recipe_comments

  has_many :user_recipes
  has_many :user_ingredients

  has_many :forum_posts

  has_many :received_private_messages, -> {where :deleted_by_receiver => false}, class_name: 'PrivateMessage', foreign_key: 'receiver_id'
  has_many :sent_private_messages, -> {where :deleted_by_sender => false}, class_name: 'PrivateMessage', foreign_key: 'sender_id'

  has_many :recipe_images

  has_one :user_rank

  has_many :shoutbox_entries

  validates_uniqueness_of :login

  validates :login,
            :presence => true,
            :length => { :within => 2..50}

  after_commit :create_member_role

  before_create :build_user_rank

  ONLINE_TIME_RANGE = 15.minutes

  scope :forum_mods, -> { joins(:roles).where(:roles => {name: Role::FORUM_MOD}) }
  scope :online, -> { where("last_active_at > ?", Time.current - ONLINE_TIME_RANGE) }

  def add_role(name)
    role = Role.find_by_name(name)
    if self.roles.where('role_id = ?', role.id).count == 0
      self.user_roles << UserRole.create(role_id: role.id)
      return true
    else
      return false
    end
  end

  def favorite_recipes
    Recipe.user_favorites self.id
  end

  def add_favorite_recipe recipe_id
    if UserRecipe.where(:recipe_id => recipe_id, :dimension => 'favorite', :user_id => self.id).count == 0
      self.user_recipes << UserRecipe.new(:recipe_id => recipe_id, :dimension => 'favorite')
    end
  end

  def remove_favorite_recipe recipe_id
    UserRecipe.where(:recipe_id => recipe_id, :dimension => 'favorite', :user_id => self.id).destroy_all
  end

  def mybar_ingredients
    Ingredient.user_mybar self.id
  end

  def add_mybar_ingredient ingredient_id
    if UserIngredient.where(:ingredient_id => ingredient_id, :dimension => 'mybar', :user_id => self.id).count == 0
      self.user_ingredients << UserIngredient.new(:ingredient_id => ingredient_id, :dimension => 'mybar')
    end
  end

  def remove_mybar_ingredient ingredient_id
    UserIngredient.where(:ingredient_id => ingredient_id, :dimension => 'mybar', :user_id => self.id).destroy_all
  end

  def save_mybar ingredient_ids
    self.user_ingredients.destroy_all
    ingredient_ids.each do |ingredient_id|
      self.add_mybar_ingredient ingredient_id
    end
  end

  def create_member_role
    self.add_role 'member'
  end

  def role?(checkRole)
    roles.each do |role|
      if role.name == checkRole
        return true
      end
    end

    return false;
  end

  def is_online?
    if last_active_at > (Time.current - ONLINE_TIME_RANGE)
      return true
    end
    return false
  rescue NoMethodError
    false
  end

  #devise hook
  def after_database_authentication
    set_daily_login
  end

  def set_daily_login
    if last_sign_in_at.nil?
      last_sign_in = Time.current - 1.year
    else
      last_sign_in = last_sign_in_at
    end

    if Time.now.to_date > last_sign_in.to_date
      update_attribute(:daily_login_count, daily_login_count.to_i + 1)
    end
    return daily_login_count
  end

  def user_profile
    UserProfile.where(:user_id => self.id).first_or_create
  end

  def ratings_for_recipes
    ratings_given.where(rateable_type: 'Recipe', dimension: 'taste')
  end

  def has_mybar?
    user_ingredients.count > 0
  end
end
