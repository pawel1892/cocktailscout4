module BreadcrumbsHelper
  def render_breadcrumbs
    return if breadcrumbs.empty?

    # Tailwind styled breadcrumbs
    content_tag(:nav, aria: { label: "Breadcrumb" }) do
      content_tag(:ol, class: "flex items-center space-x-2") do
        breadcrumbs.each_with_index do |crumb, index|
          concat(content_tag(:li) do
            if index > 0
              concat(content_tag(:span, "/", class: "text-gray-500 mx-2"))
            end

            if (index == breadcrumbs.size - 1) || crumb[:path].nil?
              concat(content_tag(:span, crumb[:name], class: "text-cs-gold font-medium", "aria-current": "page"))
            else
              concat(link_to(crumb[:name], crumb[:path], class: "text-gray-400 hover:text-cs-gold transition"))
            end
          end)
        end
      end
    end
  end
end
