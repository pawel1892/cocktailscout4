class UserAvatarsController < ApplicationController
  before_action :require_authentication

  def create
    Current.user.avatar.attach(params.require(:avatar))
    if Current.user.valid?
      Current.user.avatar.variant(:small).processed
      Current.user.avatar.variant(:medium).processed
      render json: avatar_json(Current.user)
    else
      render json: { errors: Current.user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    Current.user.avatar.purge
    render json: avatar_json(Current.user)
  end

  private

  def avatar_json(user)
    {
      avatar_url_small:  user.avatar_path(:small),
      avatar_url_medium: user.avatar_path(:medium)
    }
  end
end
