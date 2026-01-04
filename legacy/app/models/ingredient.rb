class Ingredient < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_paper_trail

  has_many :recipe_ingredients
  has_many :recipes, :through => :recipe_ingredients

  has_many :user_ingredients

  scope :user_mybar, lambda{ |user_id| joins(:user_ingredients).where('user_ingredients.user_id = ? AND user_ingredients.dimension = ?', user_id, 'mybar')}

  def is_in_mybar?(user)
    if UserIngredient.where(:ingredient_id_id => self.id, :dimension => 'mybar', :user_id => user.id).count > 0
      return true
    end

    return false
  end
end
