class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  helper_method :sort_column, :sort_direction

  def index
    add_breadcrumb "Community", community_path
    add_breadcrumb "Benutzer"

    query = User.left_joins(:user_stat).includes(:roles)

    # Search by username
    if params[:q].present?
      query = query.where("username LIKE ?", "%#{params[:q]}%")
    end

    # Filter to show only users with roles (admins/moderators)
    if params[:moderators_only] == "1"
      # When using distinct, we need to explicitly select the ORDER BY columns
      # to satisfy MySQL's ONLY_FULL_GROUP_BY requirement
      query = query.joins(:roles)
                   .select("users.*, user_stats.points")
                   .distinct
    end

    @pagy, @users = pagy(query.order("#{sort_column} #{sort_direction}"))
  end

  private

  def sort_column
    %w[username last_seen_at user_stats.points created_at].include?(params[:sort]) ? params[:sort] : "user_stats.points"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
