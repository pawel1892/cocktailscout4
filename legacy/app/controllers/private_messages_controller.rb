class PrivateMessagesController < ApplicationController
  load_and_authorize_resource

  before_action :set_private_message, only: [:show, :destroy]
  before_action :set_receiver, only: [:new]

  # GET /private_messages
  def index
    @mailbox = params.has_key?(:mailbox) ? params[:mailbox] : 'inbox'
    if @mailbox == 'outbox'
      @private_messages = current_user.sent_private_messages.order('created_at DESC').page(params[:page]).per(15)
    else
      private_messages = current_user.received_private_messages.order('created_at DESC')
      if params.has_key?(:unread)
        private_messages = private_messages.unread
      end
      @private_messages = private_messages.page(params[:page]).per(15)
    end
  end

  # GET /private_messages/1
  def show
    if @role == :receiver
      @private_message.update(:read => true)
    end
  end

  # GET /private_messages/new
  def new
    @private_message = PrivateMessage.new
  end

  # POST /private_messages
  def create
    @private_message = PrivateMessage.new(private_message_params)
    @private_message.sender_id = current_user.id
    @private_message.message.gsub!("\n", '<br />')
    @receiver = User.find(private_message_params[:receiver_id])

    if @private_message.save
      redirect_to private_messages_url(:mailbox => :outbox), :flash => { :success => "Deine Nachricht wurde gesendet." }
    else
      render action: 'new'
    end
  end

  # DELETE /private_messages/1
  def destroy
    if @role == :sender
      @private_message.update(:deleted_by_sender => true)
      redirect_to private_messages_url(mailbox: :outbox), :flash => { :success => 'Nachricht wurde gelöscht' }
    elsif  @role == :receiver
      @private_message.update(:deleted_by_receiver => true)
      redirect_to private_messages_url, :flash => { :success => 'Nachricht wurde gelöscht' }
    else
      redirect_to private_messages_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_private_message
      @private_message = PrivateMessage.find(params[:id])
      if current_user.id == @private_message.receiver_id && @private_message.deleted_by_receiver == false
        @role = :receiver
      elsif current_user.id == @private_message.sender_id && @private_message.deleted_by_sender == false
        @role = :sender
      else
        raise CanCan::AccessDenied
      end
    end

    def set_receiver
      @receiver = User.find(params[:receiver_id])
    end

    # Only allow a trusted parameter "white list" through.
    def private_message_params
      params.require(:private_message).permit(:sender_id, :receiver_id, :subject, :message, :read, :deleted_by_receiver, :deleted_by_sender)
    end
end
