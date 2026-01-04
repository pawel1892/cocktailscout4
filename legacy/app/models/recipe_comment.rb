class RecipeComment < ActiveRecord::Base

  belongs_to :recipe
  belongs_to :user

  validates :comment,
            :presence => true,
            :length => { :within => 3..50000}
end
