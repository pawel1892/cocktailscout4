class UsersController < ApplicationController
  load_and_authorize_resource

  helper_method :sort_column, :sort_direction

  def index
    @users = User.distinct.joins(:user_rank).where.not(user_ranks:{points:0}).page(params[:page]).per(50)

    #sorting
    if (sort_column == 'user_points')
      @users = @users.order("user_ranks.points #{sort_direction}")
    else
      @users = @users.order(sort_column + " " + sort_direction)
    end
  end

  private

  def sort_column
    %w(login last_sign_in_at user_points created_at).include?(params[:sort]) ? params[:sort] : "user_points"
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "desc"
  end

end