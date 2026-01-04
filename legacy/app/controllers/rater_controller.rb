class RaterController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create

    authorize! :rater, :create

    if current_user.present?
      obj = eval "#{params[:klass]}.find(#{params[:id]})"

      #render :json => obj

      if params[:dimension].present?
        obj.rate params[:score].to_i, current_user, "#{params[:dimension]}"
      else
        obj.rate params[:score].to_i, current_user
      end



      render :json => true
    else
      render :json => false
    end
  end

end
