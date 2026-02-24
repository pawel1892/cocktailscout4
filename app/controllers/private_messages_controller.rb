class PrivateMessagesController < ApplicationController
  before_action :set_message, only: [ :show, :destroy ]
  before_action :set_receiver, only: [ :new ]
  before_action :authorize_message_access, only: [ :show, :destroy ]

  def index
    add_breadcrumb "Nachrichten"
    @pagy, @messages = pagy(
      PrivateMessage.received_by(Current.user).includes(:sender),
      limit: 20
    )
    @unread_count = Current.user.unread_messages_count
  end

  def sent
    add_breadcrumb "Nachrichten", private_messages_path
    add_breadcrumb "Gesendet"
    @pagy, @messages = pagy(
      PrivateMessage.sent_by(Current.user).includes(:receiver),
      limit: 20
    )
  end

  def show
    add_breadcrumb "Nachrichten", private_messages_path
    add_breadcrumb @message.subject

    # Mark as read if user is receiver
    if @role == :receiver && !@message.read
      @message.update(read: true)
    end
  end

  def new
    add_breadcrumb "Nachrichten", private_messages_path
    add_breadcrumb "Neue Nachricht"
    @message = PrivateMessage.new
  end

  def create
    @message = PrivateMessage.new(message_params)
    @message.sender = Current.user

    if @message.save
      redirect_to sent_private_messages_path,
        notice: "Nachricht wurde erfolgreich gesendet."
    else
      @receiver = User.find_by(id: message_params[:receiver_id])
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    if @role == :sender
      @message.update(deleted_by_sender: true)
      redirect_to sent_private_messages_path,
        notice: "Nachricht wurde gelöscht."
    elsif @role == :receiver
      @message.update(deleted_by_receiver: true)
      redirect_to private_messages_path,
        notice: "Nachricht wurde gelöscht."
    end
  end

  def unread_count
    render json: {
      success: true,
      count: Current.user.unread_messages_count
    }
  end

  private

  def set_message
    @message = PrivateMessage.find(params[:id])

    # Determine user's role
    if Current.user.id == @message.receiver_id && !@message.deleted_by_receiver
      @role = :receiver
    elsif Current.user.id == @message.sender_id && !@message.deleted_by_sender
      @role = :sender
    else
      @role = :unauthorized
    end
  end

  def authorize_message_access
    if @role == :unauthorized
      redirect_to private_messages_path,
        alert: "Sie haben keine Berechtigung, diese Nachricht zu sehen."
    end
  end

  def set_receiver
    if params[:receiver_id].present?
      @receiver = User.find_by(id: params[:receiver_id])
      unless @receiver
        redirect_to private_messages_path,
          alert: "Empfänger nicht gefunden."
      end
    end
  end

  def message_params
    params.require(:private_message).permit(:receiver_id, :subject, :body)
  end
end
