require 'rails_helper'

RSpec.describe "DesignSystem", type: :request do
  describe "GET /design-system" do
    it "is publicly accessible" do
      get design_system_path
      expect(response).to have_http_status(:success)
    end
  end
end
