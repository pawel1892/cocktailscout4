module BreadcrumbsHelper
  def render_breadcrumbs
    return if breadcrumbs.size <= 1

    content_tag(:nav, class: "mb-5", aria: { label: "Breadcrumb" }) do
      content_tag(:ol, class: "flex flex-wrap items-center gap-1.5 text-xs text-cs-ink-500") do
        breadcrumbs.each_with_index do |crumb, index|
          concat(content_tag(:li) do
            if index > 0
              concat(content_tag(:i, "", class: "fa-solid fa-chevron-right text-[9px] text-cs-ink-300 mx-1", aria: { hidden: true }))
            end

            if (index == breadcrumbs.size - 1) || crumb[:path].nil?
              concat(content_tag(:span, crumb[:name], class: "font-semibold text-cs-ink-700", "aria-current": "page"))
            else
              concat(link_to(crumb[:name], crumb[:path], class: "text-cs-ink-500 hover:text-cs-red-900 transition no-underline"))
            end
          end)
        end
      end
    end
  end
end
