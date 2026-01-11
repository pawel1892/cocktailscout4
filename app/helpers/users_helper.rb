module UsersHelper
  def user_badge(user)
    return "Gelöschter Benutzer" unless user

    # TODO: Link to user profile when available
    link_to "#", class: "link inline-flex items-center gap-1 font-medium hover:underline" do
      concat tag.span(user.username, class: "text-zinc-900")
      concat tag.i(class: "fa-solid fa-user rank-#{user.rank}-color")
    end
  end
end
