class CommunityController < ApplicationController
  include ActivityStreamEnrichable

  allow_unauthenticated_access

  def index
    add_breadcrumb "Community"
    @online_users = User.online.order(last_active_at: :desc)
    @activity_stream = ActivityStreamService.new(limit: 50).call
    enrich_image_events!(@activity_stream)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          online_users: @online_users.map { |u| { id: u.id, username: u.username, rank: u.rank } },
          activity_stream: @activity_stream
        }
      end
    end
  end
end
