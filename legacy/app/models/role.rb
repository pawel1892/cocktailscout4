class Role < ActiveRecord::Base
  has_many :user_roles
  has_many :users, :through => :user_roles

  MEMBER      = 'meber'
  FORUM_MOD   = 'forum_moderator'
  RECIPE_MOD  = 'recipe_moderator'
  ADMIN       = 'admin'
  IMAGE_MOD   = 'image_moderator'
end
