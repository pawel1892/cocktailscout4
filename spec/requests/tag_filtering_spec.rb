require 'rails_helper'

RSpec.describe "Tag Filtering", type: :request do
  let!(:recipe1) { create(:recipe, title: "Rum Drink") }
  let!(:recipe2) { create(:recipe, title: "Gin Drink") }

  before do
    recipe1.tag_list.add("Rum")
    recipe1.save
    recipe2.tag_list.add("Gin")
    recipe2.save
  end

  describe "GET /tag/:tag" do
    it "filters recipes by tag" do
      get tag_path(tag: "Rum")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Rum Drink")
      expect(response.body).not_to include("Gin Drink")
    end

    it "handles tags with spaces" do
      recipe1.tag_list.add("Summer Drink")
      recipe1.save

      get tag_path(tag: "Summer Drink")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Rum Drink")
    end

    it "shows active filter when filtered by tag" do
      get tag_path(tag: "Rum")
      expect(response.body).to include("Aktive Filter")
      expect(response.body).to include("Tag: Rum")
    end
  end
end
