require 'rails_helper'

describe PrivateMessage do
  it "has a valid factory" do
    expect(FactoryGirl.create(:private_message)).to be_valid
  end

  describe 'report_to_forum_mods' do
    let(:sender) { create :user }
    let!(:forum_mods) { create_list :forum_moderator_user, 2 }
    let!(:forum_post) { create :forum_post }

    it 'reports to all mods' do
      expect {
        PrivateMessage.report_to_forum_mods(sender, 'http://ilo.veyourm.om')
      }.to change { PrivateMessage.count }.by 2
    end
  end

end
