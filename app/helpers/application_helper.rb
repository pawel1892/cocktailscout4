module ApplicationHelper
  include Pagy::Frontend

  def pagy_seo_tags(pagy)
    tags = []
    tags << tag.link(rel: "prev", href: pagy_url_for(pagy, pagy.prev)) if pagy.prev
    tags << tag.link(rel: "next", href: pagy_url_for(pagy, pagy.next)) if pagy.next
    safe_join(tags)
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    
    # Icons for sort direction
    icon = ""
    if column == sort_column
      icon = sort_direction == "asc" ? " ▲" : " ▼"
    end

    link_to request.query_parameters.merge(sort: column, direction: direction), class: "flex items-center group" do
      tag.span(title, class: "group-hover:text-gray-700 transition-colors") +
      tag.span(icon, class: "ml-1 text-xs text-cs-gold")
    end
  end

  def rating_badge_class(score)
    score = score.to_f
    return "bg-gray-400 text-white" if score.zero?
    return "bg-red-600 text-white" if score < 4
    return "bg-orange-500 text-white" if score < 6
    return "bg-yellow-500 text-white" if score < 7.5
    return "bg-lime-600 text-white" if score < 9
    "bg-green-700 text-white"
  end
end
