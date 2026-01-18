require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /impressum" do
    it "returns http success" do
      get "/impressum"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /datenschutz" do
    it "returns http success" do
      get "/datenschutz"
      expect(response).to have_http_status(:success)
    end
  end
end
