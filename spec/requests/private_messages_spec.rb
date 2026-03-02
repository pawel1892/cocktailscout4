require 'rails_helper'

RSpec.describe "PrivateMessages", type: :request do
  include AuthenticationHelpers

  let(:sender) { create(:user) }
  let(:receiver) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /nachrichten" do
    context "when authenticated" do
      before { sign_in(receiver) }

      it "returns http success" do
        get private_messages_path
        expect(response).to have_http_status(:success)
      end

      it "displays received messages" do
        message = create(:private_message, sender: sender, receiver: receiver)
        get private_messages_path
        expect(response.body).to include(message.body)
      end

      it "displays sent messages (unified conversation view)" do
        message = create(:private_message, sender: receiver, receiver: other_user)
        get private_messages_path
        expect(response.body).to include(message.body)
      end

      it "does not display messages deleted by receiver" do
        message = create(:private_message, :deleted_by_receiver, sender: sender, receiver: receiver)
        get private_messages_path
        expect(response.body).not_to include(message.body)
      end

      it "does not display messages between other users" do
        message_between_others = create(:private_message, sender: sender, receiver: other_user, body: "Private between others body")
        get private_messages_path
        expect(response.body).not_to include("Private between others body")
      end

      it "shows only one row per conversation partner" do
        create(:private_message, sender: sender, receiver: receiver, body: "First message body", created_at: 2.hours.ago)
        create(:private_message, sender: sender, receiver: receiver, body: "Second message body", created_at: 1.hour.ago)
        get private_messages_path
        expect(response.body).to include("Second message body")
        expect(response.body).not_to include("First message body")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get private_messages_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /nachrichten/sent" do
    context "when authenticated" do
      before { sign_in(sender) }

      it "returns http success" do
        get sent_private_messages_path
        expect(response).to have_http_status(:success)
      end

      it "displays sent messages" do
        message = create(:private_message, sender: sender, receiver: receiver)
        get sent_private_messages_path
        expect(response.body).to include(message.body)
      end

      it "displays received messages (unified conversation view)" do
        message = create(:private_message, sender: other_user, receiver: sender)
        get sent_private_messages_path
        expect(response.body).to include(message.body)
      end

      it "does not display messages deleted by sender" do
        message = create(:private_message, :deleted_by_sender, sender: sender, receiver: receiver)
        get sent_private_messages_path
        expect(response.body).not_to include(message.body)
      end

      it "does not display messages sent by other users" do
        message_from_others = create(:private_message, sender: other_user, receiver: receiver, body: "Sent by another user body")
        get sent_private_messages_path
        expect(response.body).not_to include("Sent by another user body")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get sent_private_messages_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /nachrichten/:id" do
    let(:message) { create(:private_message, sender: sender, receiver: receiver, read: false) }

    context "when authenticated as receiver" do
      before { sign_in(receiver) }

      it "returns http success" do
        get private_message_path(message)
        expect(response).to have_http_status(:success)
      end

      it "displays message content" do
        get private_message_path(message)
        expect(response.body).to include(message.body)
      end

      it "marks message as read" do
        expect {
          get private_message_path(message)
        }.to change { message.reload.read }.from(false).to(true)
      end

      it "marks all unread messages from sender as read" do
        message2 = create(:private_message, sender: sender, receiver: receiver, read: false)
        get private_message_path(message)
        expect(message.reload.read).to be true
        expect(message2.reload.read).to be true
      end

      it "does not mark already read message as read again" do
        message.update(read: true)
        get private_message_path(message)
        expect(message.reload.read).to be true
      end

      it "shows inline reply form" do
        get private_message_path(message)
        expect(response.body).to include("Antworten")
      end
    end

    context "when authenticated as sender" do
      before { sign_in(sender) }

      it "returns http success" do
        get private_message_path(message)
        expect(response).to have_http_status(:success)
      end

      it "does not mark message as read" do
        expect {
          get private_message_path(message)
        }.not_to change { message.reload.read }
      end
    end

    context "when authenticated as unauthorized user" do
      before { sign_in(other_user) }

      it "redirects with alert" do
        get private_message_path(message)
        expect(response).to redirect_to(private_messages_path)
        follow_redirect!
        expect(response.body).to include("keine Berechtigung")
      end
    end

    context "when message is deleted by receiver" do
      let(:deleted_message) { create(:private_message, :deleted_by_receiver, sender: sender, receiver: receiver) }
      before { sign_in(receiver) }

      it "redirects with alert" do
        get private_message_path(deleted_message)
        expect(response).to redirect_to(private_messages_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get private_message_path(message)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /nachrichten/new" do
    context "when authenticated" do
      before { sign_in(sender) }

      it "returns http success" do
        get new_private_message_path
        expect(response).to have_http_status(:success)
      end

      it "accepts receiver_id parameter" do
        get new_private_message_path(receiver_id: receiver.id)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(receiver.username)
      end

      it "redirects with alert if receiver not found" do
        get new_private_message_path(receiver_id: 99999)
        expect(response).to redirect_to(private_messages_path)
        follow_redirect!
        expect(response.body).to include("nicht gefunden")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_private_message_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /nachrichten" do
    context "when authenticated" do
      before { sign_in(sender) }

      it "creates a new message" do
        expect {
          post private_messages_path, params: {
            private_message: {
              receiver_id: receiver.id,
              body: "Test Body"
            }
          }
        }.to change(PrivateMessage, :count).by(1)

        message = PrivateMessage.last
        expect(message.sender).to eq(sender)
        expect(message.receiver).to eq(receiver)
        expect(message.subject).to eq("Nachricht")
        expect(message.body).to eq("Test Body")
        expect(message.read).to be false
      end

      it "redirects to message thread on success" do
        post private_messages_path, params: {
          private_message: {
            receiver_id: receiver.id,
            body: "Test Body"
          }
        }
        expect(response).to redirect_to(private_message_path(PrivateMessage.last))
        follow_redirect!
        expect(response.body).to include("erfolgreich gesendet")
      end

      it "fails with missing body" do
        expect {
          post private_messages_path, params: {
            private_message: {
              receiver_id: receiver.id,
              body: ""
            }
          }
        }.not_to change(PrivateMessage, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "fails with missing receiver" do
        expect {
          post private_messages_path, params: {
            private_message: {
              receiver_id: nil,
              body: "Test Body"
            }
          }
        }.not_to change(PrivateMessage, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post private_messages_path, params: {
          private_message: {
            receiver_id: receiver.id,
            body: "Test"
          }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /nachrichten/:id" do
    context "when authenticated as receiver" do
      let(:message) { create(:private_message, sender: sender, receiver: receiver) }
      before { sign_in(receiver) }

      it "soft deletes the message for receiver" do
        expect {
          delete private_message_path(message)
        }.to change { message.reload.deleted_by_receiver }.from(false).to(true)
      end

      it "does not delete messages for the sender" do
        delete private_message_path(message)
        expect(message.reload.deleted_by_sender).to be false
      end

      it "does not delete other messages in the conversation" do
        message2 = create(:private_message, sender: sender, receiver: receiver)
        delete private_message_path(message)
        expect(message2.reload.deleted_by_receiver).to be false
      end

      it "redirects to remaining message in thread" do
        message2 = create(:private_message, sender: sender, receiver: receiver)
        delete private_message_path(message)
        expect(response).to redirect_to(private_message_path(message2))
      end

      it "redirects to inbox when no messages remain" do
        delete private_message_path(message)
        expect(response).to redirect_to(private_messages_path)
        follow_redirect!
        expect(response.body).to include("gelöscht")
      end
    end

    context "when authenticated as sender" do
      let(:message) { create(:private_message, sender: sender, receiver: receiver) }
      before { sign_in(sender) }

      it "soft deletes the message for sender" do
        expect {
          delete private_message_path(message)
        }.to change { message.reload.deleted_by_sender }.from(false).to(true)
      end

      it "does not delete messages for the receiver" do
        delete private_message_path(message)
        expect(message.reload.deleted_by_receiver).to be false
      end

      it "does not delete other messages in the conversation" do
        message2 = create(:private_message, sender: sender, receiver: receiver)
        delete private_message_path(message)
        expect(message2.reload.deleted_by_sender).to be false
      end

      it "redirects to remaining message in thread" do
        message2 = create(:private_message, sender: sender, receiver: receiver)
        delete private_message_path(message)
        expect(response).to redirect_to(private_message_path(message2))
      end

      it "redirects to inbox when no messages remain" do
        delete private_message_path(message)
        expect(response).to redirect_to(private_messages_path)
        follow_redirect!
        expect(response.body).to include("gelöscht")
      end
    end

    context "when authenticated as unauthorized user" do
      let(:message) { create(:private_message, sender: sender, receiver: receiver) }
      before { sign_in(other_user) }

      it "redirects with alert" do
        delete private_message_path(message)
        expect(response).to redirect_to(private_messages_path)
      end

      it "does not delete the message" do
        delete private_message_path(message)
        message.reload
        expect(message.deleted_by_sender).to be false
        expect(message.deleted_by_receiver).to be false
      end
    end

    context "when not authenticated" do
      let(:message) { create(:private_message, sender: sender, receiver: receiver) }

      it "redirects to login" do
        delete private_message_path(message)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /nachrichten/unread_count" do
    context "when authenticated" do
      before { sign_in(receiver) }

      it "returns unread count as JSON" do
        create_list(:private_message, 3, sender: sender, receiver: receiver, read: false)
        create(:private_message, sender: sender, receiver: receiver, read: true)

        get unread_count_private_messages_path
        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["count"]).to eq(3)
      end

      it "returns 0 when no unread messages" do
        get unread_count_private_messages_path
        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        expect(json["count"]).to eq(0)
      end

      it "excludes deleted messages from count" do
        create(:private_message, sender: sender, receiver: receiver, read: false)
        create(:private_message, :deleted_by_receiver, sender: sender, receiver: receiver, read: false)

        get unread_count_private_messages_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get unread_count_private_messages_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "Pagination" do
    before { sign_in(receiver) }

    it "paginates inbox conversations" do
      # Need 21+ distinct conversation partners to trigger pagination
      senders = create_list(:user, 21)
      senders.each { |s| create(:private_message, sender: s, receiver: receiver) }
      get private_messages_path

      expect(response.body).to match(/page=2/)
    end

    it "paginates sent conversations" do
      receivers = create_list(:user, 21)
      receivers.each { |r| create(:private_message, sender: receiver, receiver: r) }
      get sent_private_messages_path

      expect(response.body).to match(/page=2/)
    end
  end
end
