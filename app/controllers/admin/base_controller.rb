module Admin
  class BaseController < ApplicationController
    before_action :require_moderator!

    layout "admin"

    private

    def require_moderator!
      unless Current.user&.moderator?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end
  end
end
