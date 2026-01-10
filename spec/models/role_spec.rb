require 'rails_helper'

RSpec.describe Role, type: :model do
  describe "Associations" do
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:users).through(:user_roles) }
  end

  describe "Validations" do
    subject { create(:role) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end
end
