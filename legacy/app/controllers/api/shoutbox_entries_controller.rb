class Api::ShoutboxEntriesController < Api::BaseController

  def index
    @shoutbox_entries = ShoutboxEntry.order(:created_at).last(10)
  end

  def create
    @shoutbox_entry = ShoutboxEntry.new(shoutbox_entries_params.merge({user_id: current_user.id}))

    if @shoutbox_entry.save
      @shoutbox_entries = ShoutboxEntry.order(:created_at).last(10)
      render :index
    else
    end
  end

  protected

  def shoutbox_entries_params
    params.require(:shoutbox_entry).permit(:content)
  end
end
