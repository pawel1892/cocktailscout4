module UsersHelper
  def user_badge(user)
    unless user
      return tag.span(class: "inline-flex items-center gap-1 opacity-80") do
        concat tag.span("Gelöschter Benutzer", class: "text-gray-500 font-medium")
        concat tag.i(class: "fa-solid fa-user text-gray-400")
      end
    end

    tag.button(
      type: "button",
      class: "link inline-flex items-center gap-1 font-medium hover:underline cursor-pointer user-profile-trigger",
      data: { user_id: user.id }
    ) do
      concat tag.span(user.username, class: "text-zinc-900")
      concat tag.i(class: "fa-solid fa-user rank-#{user.rank}-color")
      concat tag.i(class: "fa-solid fa-wifi text-green-500 text-xs", title: "Online") if user.online?
    end
  end
end
