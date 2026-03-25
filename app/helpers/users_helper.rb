module UsersHelper
  def user_badge(user)
    unless user
      return tag.span(class: "inline-flex items-center gap-1 opacity-80") do
        concat tag.span("Gelöschter Benutzer", class: "text-gray-500 font-medium")
        concat tag.i(class: "fa-solid fa-user text-gray-400 text-xs")
      end
    end

    tag.button(
      type: "button",
      class: "link inline-flex items-center gap-1.5 font-medium hover:underline cursor-pointer user-profile-trigger",
      data: { user_id: user.id }
    ) do
      concat avatar_circle(user)
      concat tag.span(user.username, class: "text-zinc-900")
      concat tag.i(class: "fa-solid fa-wifi text-green-500 text-xs", title: "Online") if user.online?
    end
  end

  private

  def avatar_circle(user)
    if user.avatar.attached?
      image_tag(
        user.avatar.variant(:small),
        class: "w-7 h-7 rounded-full object-cover flex-shrink-0",
        alt: user.username
      )
    else
      rank = user.respond_to?(:rank) ? user.rank : 0
      initial = user.username[0]&.upcase || "?"
      tag.span(
        initial,
        class: "w-7 h-7 rounded-full flex-shrink-0 inline-flex items-center justify-center text-white text-xs font-bold rank-#{rank}-bg"
      )
    end
  end
end
