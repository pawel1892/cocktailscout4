module RecipeCommentsHelper
  def can_edit_comment?(comment)
    return false unless Current.user
    return true if comment.user == Current.user
    can_delete_comment?(comment)
  end

  def can_delete_comment?(comment)
    return false unless Current.user
    Current.user.can_moderate_recipe?
  end
end
