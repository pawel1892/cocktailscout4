require "spec_helper"

describe UserProfilesController do
  describe "routing" do

    it "routes to #show" do
      expect(get("/user_profiles/1")).to route_to("user_profiles#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/user_profile/edit")).to route_to("user_profiles#edit")
    end

    it "routes to #update" do
      expect(put("/user_profile")).to route_to("user_profiles#update")
    end

  end
end
