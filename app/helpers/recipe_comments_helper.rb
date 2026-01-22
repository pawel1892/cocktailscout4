module RecipeCommentsHelper
  def can_modify_comment?(comment)
    return false unless Current.user
    return true if comment.user == Current.user
    return true if Current.user.admin?
    return true if Current.user.recipe_moderator?
    return true if Current.user.forum_moderator?
    false
  end
end
