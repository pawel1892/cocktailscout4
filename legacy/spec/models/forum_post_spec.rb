require 'rails_helper'

describe ForumPost do
  it "has a valid factory" do
    expect(FactoryGirl.create(:forum_post)).to be_valid
  end
end
