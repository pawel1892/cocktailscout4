class UserProfilesController < ApplicationController
  allow_unauthenticated_access only: [ :show ]
  before_action :set_user, only: [ :show, :update ]
  before_action :authorize_user, only: [ :update ]

  def show
    respond_to do |format|
      format.json do
        render json: {
          id: @user.id,
          username: @user.username,
          prename: @user.prename,
          gender: @user.gender,
          location: @user.location,
          homepage: @user.homepage,
          rank: @user.rank,
          points: @user.points,
          sign_in_count: @user.sign_in_count,
          last_seen_at: @user.last_seen_at,
          created_at: @user.created_at,
          roles: @user.roles.map { |r| { name: r.name, display_name: r.display_name } },
          # Stats for display
          recipes_count: @user.recipes.count,
          recipe_images_count: @user.recipe_images.approved.count,
          recipe_comments_count: @user.recipe_comments.count,
          ratings_count: @user.ratings.where(rateable_type: "Recipe").count,
          forum_posts_count: @user.forum_posts.count
        }
      end
    end
  end

  def update
    if @user.update(profile_params)
      render json: {
        id: @user.id,
        username: @user.username,
        prename: @user.prename,
        gender: @user.gender,
        location: @user.location,
        homepage: @user.homepage,
        rank: @user.rank,
        points: @user.points,
        sign_in_count: @user.sign_in_count,
        last_active_at: @user.last_active_at,
        created_at: @user.created_at,
        roles: @user.roles.map { |r| { name: r.name, display_name: r.display_name } },
        recipes_count: @user.recipes.count,
        recipe_images_count: @user.recipe_images.approved.count,
        recipe_comments_count: @user.recipe_comments.count,
        ratings_count: @user.ratings.where(rateable_type: "Recipe").count,
        forum_posts_count: @user.forum_posts.count
      }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    unless Current.user && Current.user.id == @user.id
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def profile_params
    params.require(:user).permit(:prename, :gender, :location, :homepage)
  end
end
