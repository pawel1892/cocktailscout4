class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.role? 'admin'
      can :manage, :all
    end
    if user.role? 'image_moderator'
      image_moderator_role(user)
    end
    if user.role? 'forum_moderator'
      forum_moderator_role(user)
    end
    if user.role? 'recipe_moderator'
      recipe_moderator_role(user)
    end
    if user.role? 'member'
      member_role(user)
    end
    guest_role(user)
  end

  def recipe_moderator_role(user)
    can :manage, Ingredient
    can :manage, Recipe
  end

  def image_moderator_role(user)
    can :approve, RecipeImage
  end

  def forum_moderator_role(user)
    can :update, ForumPost
    can :destroy, ForumPost
  end

  def member_role(user)
    # all permissions for members
    can :create, RecipeComment
    can :update, RecipeComment do |recipe_comment|
      recipe_comment.try(:user) == user
    end
    can :create, Recipe
    can :update, Recipe do |recipe|
      recipe.try(:user) == user
    end
    can :update_tags, Recipe
    can :create, RecipeImage
    can :rater, :create
    can :manage, UserRecipe
    can :manage, UserIngredient

    #Forum
    can :create, ForumThread
    can :create, ForumPost
    can :update, ForumPost do |forum_post|
      forum_post.try(:user) == user
    end
    can :report, ForumPost

    can :manage, PrivateMessage
    can :manage, UserProfile
  end

  def guest_role(user)
    can :read, Recipe
    can [:list, :tag, :tag_cloud, :top_lists], Recipe
    can :read, RecipeComment
    can :read, RecipeImage

    #BlogEntry
    can :read, BlogEntry

    #Forum
    can :read, ForumTopic
    can :read, ForumThread
    can :read, ForumPost

    #User
    can :read, User
    can [:whoiswho], User
    can :read, UserProfile
  end
end
