require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  let!(:user) { create(:user, email_address: "test@example.com", username: "testuser", password: "password") }

  describe "POST /session" do
    it "logs in with email address" do
      post session_path, params: { email_address: "test@example.com", password: "password" }
      expect(response).to redirect_to(root_path)
    end

    it "logs in with username" do
      post session_path, params: { email_address: "testuser", password: "password" }
      expect(response).to redirect_to(root_path)
    end

    it "fails with wrong password" do
      post session_path, params: { email_address: "testuser", password: "wrong" }
      expect(response).to redirect_to(new_session_path)
    end

    it "fails with non-existent user" do
      post session_path, params: { email_address: "nobody", password: "password" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /registration" do
    it "registers a new user with username" do
      expect {
        post registration_path, params: { user: { email_address: "new@example.com", username: "newuser", password: "password", password_confirmation: "password" } }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      user = User.last
      expect(user.username).to eq("newuser")
      expect(user.email_address).to eq("new@example.com")
    end

    it "fails without username" do
      expect {
        post registration_path, params: { user: { email_address: "nouser@example.com", password: "password", password_confirmation: "password" } }
      }.not_to change(User, :count)



      expect(response).to have_http_status(:unprocessable_content)
    end



    it "fails with duplicate email" do
      create(:user, email_address: "taken@example.com", username: "takenuser")



      expect {
        post registration_path, params: { user: { email_address: "taken@example.com", username: "newuser", password: "password", password_confirmation: "password" } }
      }.not_to change(User, :count)



      expect(response).to have_http_status(:unprocessable_content)

      expect(response.body).to include("Email Adresse ist bereits vergeben")
    end
  end
end
