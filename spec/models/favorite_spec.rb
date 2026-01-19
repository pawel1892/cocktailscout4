require 'rails_helper'

RSpec.describe Favorite, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:favoritable) }
  end

  describe "Validations" do
    subject { build(:favorite) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:favoritable_type, :favoritable_id).with_message("has already favorited this item") }
  end
end
