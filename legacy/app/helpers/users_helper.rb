module UsersHelper
  def user_profile (user = nil)
    if user
      user_profile = user.user_profile
      render partial: 'users/user_profile_link', locals: {user: user, user_profile: user_profile}
    else
      return 'gelöschter Benutzer'
    end
  end
end
