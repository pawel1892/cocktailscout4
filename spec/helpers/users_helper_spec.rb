require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe "#user_badge" do
    context "with a valid user" do
      let(:user) { create(:user, username: "testuser") }

      before do
        allow(user).to receive(:rank).and_return(5)
        allow(user).to receive(:id).and_return(123)
        allow(user).to receive(:online?).and_return(false)
        allow(user).to receive(:avatar_path).and_return(nil)
      end

      it "returns a user-badge element" do
        result = helper.user_badge(user)
        expect(result).to include('user-badge')
      end

      it "includes user-id attribute" do
        result = helper.user_badge(user)
        expect(result).to include('user-id="123"')
      end

      it "includes username attribute" do
        result = helper.user_badge(user)
        expect(result).to include('username="testuser"')
      end

      it "includes rank attribute" do
        result = helper.user_badge(user)
        expect(result).to include('rank="5"')
      end

      it "includes online attribute" do
        result = helper.user_badge(user)
        expect(result).to include('online=')
      end
    end

    context "with a nil user (deleted user)" do
      it "returns an empty user-badge element" do
        result = helper.user_badge(nil)
        expect(result).to include('user-badge')
        expect(result).not_to include('user-id')
      end
    end

    context "online indicator" do
      it "sets online=true when user is online" do
        user = create(:user, last_active_at: 1.minute.ago)
        allow(user).to receive(:avatar_path).and_return(nil)

        result = helper.user_badge(user)
        expect(result).to include('online="true"')
      end

      it "sets online=false when user is offline" do
        user = create(:user, last_active_at: 10.minutes.ago)
        allow(user).to receive(:avatar_path).and_return(nil)

        result = helper.user_badge(user)
        expect(result).to include('online="false"')
      end
    end

    context "with an attached avatar" do
      it "includes avatar-url-small attribute" do
        user = create(:user)
        allow(user).to receive(:online?).and_return(false)
        allow(user).to receive(:avatar_path).with(:small).and_return("/avatars/small.png")

        result = helper.user_badge(user)
        expect(result).to include('avatar-url-small="/avatars/small.png"')
      end
    end
  end
end
