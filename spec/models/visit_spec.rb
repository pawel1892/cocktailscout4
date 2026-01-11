require 'rails_helper'

RSpec.describe Visit, type: :model do
  describe "Associations" do
    it { should belong_to(:visitable) }
    it { should belong_to(:user).optional }
  end
end
