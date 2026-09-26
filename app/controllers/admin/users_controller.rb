module Admin
  class UsersController < BaseController
    before_action :require_user_admin!
    before_action :set_user, only: [ :show, :ban, :unban ]

    def index
      @users = User.all
        .then { |query| apply_filters(query) }
        .order(sort_column => sort_direction)

      @pagy, @users = pagy(@users, limit: 50)
    end

    def show
    end

    def ban
      if @user == Current.user
        redirect_to admin_user_path(@user), alert: "Du kannst dich nicht selbst sperren."
      elsif @user.can_ban_users?
        redirect_to admin_user_path(@user), alert: "Admins und Moderatoren können nicht gesperrt werden."
      elsif params[:ban_reason].blank?
        redirect_to admin_user_path(@user), alert: "Bitte gib einen Grund für die Sperre an."
      else
        @user.ban!(by: Current.user, reason: params[:ban_reason], until_time: banned_until_param)
        redirect_to admin_user_path(@user), notice: "#{@user.username} wurde gesperrt."
      end
    end

    def unban
      @user.unban!
      redirect_to admin_user_path(@user), notice: "#{@user.username} wurde entsperrt."
    end

    private

    def require_user_admin!
      unless Current.user&.can_ban_users?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end

    def set_user
      @user = User.find(params[:id])
    end

    def banned_until_param
      return if params[:banned_until].blank?

      Date.parse(params[:banned_until]).end_of_day
    rescue Date::Error
      nil
    end

    def apply_filters(query)
      query = query.banned if params[:status] == "banned"
      query = search(query) if params[:q].present?
      query
    end

    def search(query)
      term = "%#{User.sanitize_sql_like(params[:q])}%"
      query.where("users.username LIKE ? OR users.email_address LIKE ?", term, term)
    end

    def sort_column
      %w[username email_address created_at last_seen_at banned_at].include?(params[:sort]) ? params[:sort] : "created_at"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
  end
end
