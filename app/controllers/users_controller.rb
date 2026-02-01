class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  helper_method :sort_column, :sort_direction

  def index
    add_breadcrumb "Community", community_path
    add_breadcrumb "Benutzer"

    query = User.left_joins(:user_stat)

    # Search by username
    if params[:q].present?
      query = query.where("username LIKE ?", "%#{params[:q]}%")
    end

    @pagy, @users = pagy(query.order("#{sort_column} #{sort_direction}"))
  end

  private

  def sort_column
    %w[username last_active_at user_stats.points created_at].include?(params[:sort]) ? params[:sort] : "user_stats.points"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
