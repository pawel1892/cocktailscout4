require 'rails_helper'

describe "UserProfiles" do

  describe "GET /user_profiles/{var id}" do
    it "shows profile of user with id {var id}" do
      user_profile = create(:user_profile)
      visit user_profile_path(user_profile)
      expect(page).to have_content user_profile.prename
    end
  end

end
