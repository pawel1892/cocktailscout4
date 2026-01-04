module ApplicationHelper

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.permit!.merge({:sort => column, :direction => direction}), {:class => css_class}
  end

  def unread_pm_count
    return 0 if current_user.blank?
    PrivateMessage.unread_by_user(current_user).count
  end

  def images_to_approve_count
    return 0 unless can?(:approve, RecipeImage)
    RecipeImage.to_approve.count
  end

  def notification_count
    unread_pm_count + images_to_approve_count
  end
  
end
