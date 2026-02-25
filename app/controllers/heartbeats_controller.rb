class HeartbeatsController < ApplicationController
  allow_unauthenticated_access

  def create
    Current.user&.touch(:last_active_at, :last_seen_at)
    head :no_content
  end
end
