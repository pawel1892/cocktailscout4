# TODO: move to feature test

# require 'rails_helper'
#
# describe PrivateMessagesController do
#
#   before :each do
#     @user = create(:user)
#     sign_in @user
#     @incoming_message = create(:private_message, receiver: @user)
#     @outgoing_message = create(:private_message, sender: @user)
#     @message_other_user = create(:private_message)
#   end
#
#   describe "GET #index" do
#
#     context "inbox" do
#       it "creates a collection of incoming messages" do
#         get :index
#         expect(assigns(:private_messages)).to include(@incoming_message)
#         expect(assigns(:private_messages)).not_to include(@outgoing_message)
#       end
#
#       it "renders the :index view" do
#         get :index
#         expect(response).to render_template :index
#       end
#
#       it "does not contain messages for other users" do
#         get :index
#         expect(assigns(:private_messages)).not_to include(@message_other_user)
#       end
#     end
#
#     context "outbox" do
#       it "creates a collection of outgoing messages" do
#         get :index, {:mailbox => :outbox}
#         expect(assigns(:private_messages)).not_to include(@incoming_message)
#         expect(assigns(:private_messages)).to include(@outgoing_message)
#       end
#
#       it "renders the :index view" do
#         get :index
#         expect(response).to render_template :index
#       end
#
#       it "does not contain messages for other users" do
#         get :index
#         expect(assigns(:private_messages)).not_to include(@message_other_user)
#       end
#     end
#
#   end
#
#   describe "get #show" do
#     it "shows message if user is sender" do
#       get :show, {:id => @outgoing_message.id}
#       expect(assigns(:private_message)).to eq(@outgoing_message)
#     end
#
#     it "shows message if user is receiver" do
#       get :show, {:id => @incoming_message.id}
#       expect(assigns(:private_message)).to eq(@incoming_message)
#     end
#
#     it "marks message as read if user is receiver" do
#       get :show, {:id => @incoming_message.id}
#       expect(@incoming_message.reload.read).to eq(true)
#     end
#
#     it "does not show messages from other users" do
#       get :show, {:id => @message_other_user.id}
#       expect(response).to deny_access
#     end
#   end
#
# end