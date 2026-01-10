require 'rails_helper'

RSpec.describe "DesignSystem", type: :request do
  describe "GET /design-system" do
    context "when not logged in" do
      it "redirects to login page" do
        get design_system_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as regular user" do
      let(:user) { create(:user) }

      before do
        post session_url, params: { email_address: user.email_address, password: user.password }
      end

      it "redirects to root with access denied" do
        get design_system_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end

    context "when logged in as admin" do
      let(:admin) { create(:user, :admin) }

      before do
        post session_url, params: { email_address: admin.email_address, password: admin.password }
      end

      it "allows access" do
        get design_system_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
