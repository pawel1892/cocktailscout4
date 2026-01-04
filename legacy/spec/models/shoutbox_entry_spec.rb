require 'rails_helper'

RSpec.describe ShoutboxEntry, type: :model do
  describe 'factories' do
    let(:shoutbox_entry) { create :shoutbox_entry }

    it 'has a valid factory' do
      expect(shoutbox_entry).to be_valid
    end
  end
end
