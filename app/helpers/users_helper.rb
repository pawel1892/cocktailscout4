module UsersHelper
  def user_badge(user)
    unless user
      return tag.span(class: "inline-flex items-center gap-1 opacity-80") do
        concat tag.span("Gelöschter Benutzer", class: "text-gray-500 font-medium")
        concat tag.i(class: "fa-solid fa-user text-gray-400")
      end
    end

    # TODO: Link to user profile when available
    link_to "#", class: "link inline-flex items-center gap-1 font-medium hover:underline" do
      concat tag.span(user.username, class: "text-zinc-900")
      concat tag.i(class: "fa-solid fa-user rank-#{user.rank}-color")
    end
  end
end
