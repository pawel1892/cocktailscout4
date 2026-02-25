require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe "#user_badge" do
    context "with a valid user" do
      let(:user) { create(:user, username: "testuser") }

      before do
        # Mock the rank to have predictable output
        allow(user).to receive(:rank).and_return(5)
        allow(user).to receive(:id).and_return(123)
      end

      it "returns a button element with user data" do
        result = helper.user_badge(user)

        expect(result).to include('button')
        expect(result).to include('type="button"')
      end

      it "includes the username in the output" do
        result = helper.user_badge(user)

        expect(result).to include('testuser')
      end

      it "includes trigger class for profile modal" do
        result = helper.user_badge(user)

        expect(result).to include('user-profile-trigger')
      end

      it "includes rank-based color class on user icon" do
        result = helper.user_badge(user)

        expect(result).to include('fa-user')
        expect(result).to include('rank-5-color')
      end

      it "includes proper styling classes" do
        result = helper.user_badge(user)

        expect(result).to include('inline-flex')
        expect(result).to include('items-center')
        expect(result).to include('hover:underline')
        expect(result).to include('cursor-pointer')
      end

      it "stores user_id in data attribute" do
        result = helper.user_badge(user)

        expect(result).to include('data-user-id="123"')
      end
    end

    context "with a nil user (deleted user)" do
      it "returns a span element for deleted users" do
        result = helper.user_badge(nil)

        expect(result).to include('<span')
        expect(result).not_to include('button')
      end

      it "displays 'Gelöschter Benutzer' text" do
        result = helper.user_badge(nil)

        expect(result).to include('Gelöschter Benutzer')
      end

      it "includes gray styling for deleted users" do
        result = helper.user_badge(nil)

        expect(result).to include('text-gray-500')
        expect(result).to include('text-gray-400')
        expect(result).to include('opacity-80')
      end

      it "includes user icon for deleted users" do
        result = helper.user_badge(nil)

        expect(result).to include('fa-user')
      end

      it "does not include interactive elements for deleted users" do
        result = helper.user_badge(nil)

        expect(result).not_to include('user-profile-trigger')
        expect(result).not_to include('data-user-id')
      end
    end

    context "online indicator" do
      it "shows wifi icon when user is online" do
        user = create(:user, last_active_at: 1.minute.ago)
        allow(user).to receive(:rank).and_return(1)

        result = helper.user_badge(user)

        expect(result).to include("fa-wifi")
        expect(result).to include("text-green-500")
      end

      it "does not show wifi icon when user is offline" do
        user = create(:user, last_active_at: 10.minutes.ago)
        allow(user).to receive(:rank).and_return(1)

        result = helper.user_badge(user)

        expect(result).not_to include("fa-wifi")
      end

      it "does not show wifi icon when last_active_at is nil" do
        user = create(:user, last_active_at: nil)
        allow(user).to receive(:rank).and_return(1)

        result = helper.user_badge(user)

        expect(result).not_to include("fa-wifi")
      end
    end

    context "with different user ranks" do
      it "applies correct rank color for rank 0" do
        user = create(:user)
        allow(user).to receive(:rank).and_return(0)

        result = helper.user_badge(user)
        expect(result).to include('rank-0-color')
      end

      it "applies correct rank color for rank 10" do
        user = create(:user)
        allow(user).to receive(:rank).and_return(10)

        result = helper.user_badge(user)
        expect(result).to include('rank-10-color')
      end
    end
  end
end
