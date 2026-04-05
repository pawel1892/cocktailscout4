require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#sortable" do
    before do
      helper.define_singleton_method(:sort_column) { "name" }
      helper.define_singleton_method(:sort_direction) { "asc" }
    end

    def stub_request_at(path, query_params = {})
      allow(helper.request).to receive(:path).and_return(path)
      allow(helper.request).to receive(:query_parameters).and_return(query_params)
    end

    it "generates a link pointing to the current page path" do
      stub_request_at("/rezepte")
      expect(helper.sortable("name")).to include('href="/rezepte?')
    end

    it "does not route to /rezepte when on the users page" do
      stub_request_at("/benutzer")
      link = helper.sortable("username")
      expect(link).to include('href="/benutzer?')
      expect(link).not_to include("/rezepte")
    end

    it "preserves existing query parameters (e.g. tag filter)" do
      stub_request_at("/rezepte", { "tag" => "Rum" })
      link = helper.sortable("name")
      expect(link).to include("tag=Rum")
      expect(link).to include("sort=name")
    end

    it "includes sort and direction params" do
      stub_request_at("/rezepte")
      link = helper.sortable("rating", default_dir: "desc")
      expect(link).to include("sort=rating")
      expect(link).to include("direction=")
    end

    it "toggles direction when column is already sorted" do
      stub_request_at("/rezepte")
      link = helper.sortable("name")
      expect(link).to include("direction=desc")
    end
  end
end
