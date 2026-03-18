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

  describe "Counter cache" do
    let(:recipe) { create(:recipe) }
    let(:user)   { create(:user) }

    it "increments recipe favorites_count when a favorite is created" do
      expect { create(:favorite, user: user, favoritable: recipe) }
        .to change { recipe.reload.favorites_count }.by(1)
    end

    it "decrements recipe favorites_count when a favorite is destroyed" do
      favorite = create(:favorite, user: user, favoritable: recipe)
      expect { favorite.destroy }
        .to change { recipe.reload.favorites_count }.by(-1)
    end
  end
end
