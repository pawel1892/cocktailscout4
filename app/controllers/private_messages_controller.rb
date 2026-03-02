class PrivateMessagesController < ApplicationController
  before_action :set_message, only: [ :show, :destroy ]
  before_action :set_receiver, only: [ :new ]
  before_action :authorize_message_access, only: [ :show, :destroy ]

  def index
    add_breadcrumb "Nachrichten"

    latest_ids = PrivateMessage.for_user(Current.user)
      .select("MAX(id) as id, LEAST(sender_id, receiver_id) as u1, GREATEST(sender_id, receiver_id) as u2")
      .group("LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id)")
      .map(&:id)

    @pagy, @messages = pagy(
      PrivateMessage.where(id: latest_ids).includes(:sender, :receiver).order(created_at: :desc),
      limit: 20
    )

    @unread_partner_ids = PrivateMessage.where(
      receiver_id: Current.user.id, read: false, deleted_by_receiver: false
    ).distinct.pluck(:sender_id).to_set

    @unread_count = Current.user.unread_messages_count
  end

  def sent
    add_breadcrumb "Nachrichten", private_messages_path
    add_breadcrumb "Gesendet"

    latest_ids = PrivateMessage.for_user(Current.user)
      .select("MAX(id) as id, LEAST(sender_id, receiver_id) as u1, GREATEST(sender_id, receiver_id) as u2")
      .group("LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id)")
      .map(&:id)

    @pagy, @messages = pagy(
      PrivateMessage.where(id: latest_ids).includes(:sender, :receiver).order(created_at: :desc),
      limit: 20
    )

    @unread_partner_ids = PrivateMessage.where(
      receiver_id: Current.user.id, read: false, deleted_by_receiver: false
    ).distinct.pluck(:sender_id).to_set
  end

  def show
    add_breadcrumb "Nachrichten", private_messages_path
    add_breadcrumb @message.subject

    @other_user = Current.user.id == @message.receiver_id ? @message.sender : @message.receiver

    @conversation = PrivateMessage.between_users(Current.user.id, @other_user.id)
                                   .for_user(Current.user)
                                   .includes(:sender, :receiver)
                                   .reorder(created_at: :desc)

    PrivateMessage.where(
      sender_id: @other_user.id,
      receiver_id: Current.user.id,
      read: false,
      deleted_by_receiver: false
    ).update_all(read: true)
  end

  def new
    add_breadcrumb "Nachrichten", private_messages_path
    add_breadcrumb "Neue Nachricht"
    @message = PrivateMessage.new
  end

  def create
    @message = PrivateMessage.new(message_params)
    @message.sender = Current.user
    @message.subject = "Nachricht"

    if @message.save
      redirect_to private_message_path(@message), notice: "Nachricht wurde erfolgreich gesendet."
    else
      @receiver = User.find_by(id: message_params[:receiver_id])
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    other_id = Current.user.id == @message.receiver_id ? @message.sender_id : @message.receiver_id

    if @role == :receiver
      @message.update(deleted_by_receiver: true)
    elsif @role == :sender
      @message.update(deleted_by_sender: true)
    end

    remaining = PrivateMessage.between_users(Current.user.id, other_id)
                              .for_user(Current.user)
                              .first

    if remaining
      redirect_to private_message_path(remaining), notice: "Nachricht wurde gelöscht."
    else
      redirect_to private_messages_path, notice: "Nachricht wurde gelöscht."
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
