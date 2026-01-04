class UserProfilesController < ApplicationController
  load_and_authorize_resource
  before_action :set_user_profile, only: [:show, :destroy]
  before_action :set_own_user_profile, only: [:edit, :update]

  # GET /user_profiles/1
  def show
  end

  # GET /user_profile/edit
  def edit
  end

  # PATCH/PUT /user_profile
  def update
    if @user_profile.update(user_profile_params)
      redirect_to @user_profile, notice: 'Dein Profil wurde gespeichert'
    else
      render action: 'edit'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_profile
      @user_profile = UserProfile.find(params[:id])
    end

    def set_own_user_profile
      @user_profile = current_user.user_profile
    end

    # Only allow a trusted parameter "white list" through.
    def user_profile_params
      params.require(:user_profile).permit(:gender, :prename, :public_mail, :homepage, :location, :title, :signature, :additional_data)
    end
end
