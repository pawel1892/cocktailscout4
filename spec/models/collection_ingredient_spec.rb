require 'rails_helper'

RSpec.describe CollectionIngredient, type: :model do
  describe "Associations" do
    it { should belong_to(:ingredient_collection) }
    it { should belong_to(:ingredient) }
  end

  describe "Validations" do
    subject { create(:collection_ingredient) }

    it { should validate_uniqueness_of(:ingredient_id).scoped_to(:ingredient_collection_id) }
  end

  describe "Uniqueness constraint" do
    let(:collection) { create(:ingredient_collection) }
    let(:ingredient) { create(:ingredient) }

    it "prevents duplicate ingredients in the same collection" do
      create(:collection_ingredient, ingredient_collection: collection, ingredient: ingredient)
      duplicate = build(:collection_ingredient, ingredient_collection: collection, ingredient: ingredient)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ingredient_id]).to be_present
    end

    it "allows same ingredient in different collections" do
      other_collection = create(:ingredient_collection)

      first = create(:collection_ingredient, ingredient_collection: collection, ingredient: ingredient)
      second = build(:collection_ingredient, ingredient_collection: other_collection, ingredient: ingredient)

      expect(second).to be_valid
    end

    it "allows different ingredients in the same collection" do
      other_ingredient = create(:ingredient)

      first = create(:collection_ingredient, ingredient_collection: collection, ingredient: ingredient)
      second = build(:collection_ingredient, ingredient_collection: collection, ingredient: other_ingredient)

      expect(second).to be_valid
    end
  end
end
