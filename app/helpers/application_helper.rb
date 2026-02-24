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

  def report_button(reportable, css_class: "")
    return unless Current.user

    tag.button(
      type: "button",
      class: "text-gray-400 hover:text-red-500 transition #{css_class}",
      title: "Inhalt melden",
      onclick: "window.dispatchEvent(new CustomEvent('open-report-modal', { detail: { type: '#{reportable.class.name}', id: #{reportable.id} } }))"
    ) do
      # Flag SVG
      tag.svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", class: "w-4 h-4") do
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M3 3v1.5M3 21v-6m0 0 2.77-.693a9 9 0 0 1 6.208.682l.108.054a9 9 0 0 0 6.086.71l3.114-.732a48.524 48.524 0 0 1-.005-10.499l-3.11.732a9 9 0 0 1-6.085-.711l-.108-.054a9 9 0 0 0-6.208-.682L3 4.5M3 15V4.5")
      end
    end
  end

  def status_badge(recipe)
    if recipe.is_deleted
      content_tag :span, "Gelöscht", class: "px-2 py-1 text-xs font-semibold rounded bg-red-100 text-red-800"
    elsif recipe.is_public
      content_tag :span, "Veröffentlicht", class: "px-2 py-1 text-xs font-semibold rounded bg-green-100 text-green-800"
    else
      content_tag :span, "Entwurf", class: "px-2 py-1 text-xs font-semibold rounded bg-yellow-100 text-yellow-800"
    end
  end
end
