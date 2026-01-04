require "spec_helper"

describe PrivateMessagesController do
  describe "routing" do

    it "routes to #index" do
      expect(get("/private_messages")).to route_to("private_messages#index")
    end

    it "routes to #new" do
      expect(get("/private_messages/new")).to route_to("private_messages#new")
    end

    it "routes to #show" do
      expect(get("/private_messages/1")).to route_to("private_messages#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/private_messages/1/edit")).to route_to("private_messages#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/private_messages")).to route_to("private_messages#create")
    end

    it "routes to #update" do
      expect(put("/private_messages/1")).to route_to("private_messages#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/private_messages/1")).to route_to("private_messages#destroy", :id => "1")
    end

  end
end
