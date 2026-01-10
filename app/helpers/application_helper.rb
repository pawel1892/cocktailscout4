module ApplicationHelper
  def pagy_seo_tags(pagy)
    tags = []
    tags << tag.link(rel: "prev", href: pagy.page_url(pagy.previous)) if pagy.previous
    tags << tag.link(rel: "next", href: pagy.page_url(pagy.next)) if pagy.next
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
end
