module UsersHelper
  def user_badge(user, layout: :horizontal)
    if user
      content_tag(:"user-badge", "",
        "user-id":           user.id,
        username:             user.username,
        rank:                 user.rank,
        "avatar-url-small":   user.avatar_path(:small).to_s,
        "avatar-url-medium":  user.avatar_path(:medium).to_s,
        online:               user.online?,
        layout:               layout
      )
    else
      content_tag(:"user-badge", "", layout: layout)
    end
  end
end
