require "rails_helper"

RSpec.describe Unit, type: :model do
  describe "validations" do
    subject { build(:unit) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_inclusion_of(:category).in_array(%w[volume count special]) }

    context "for volume and special units" do
      it "validates ml_ratio is greater than 0" do
        unit = build(:unit, category: "volume", ml_ratio: 0)
        expect(unit).not_to be_valid
        expect(unit.errors[:ml_ratio]).to include("muss größer als 0 sein")
      end
    end

    context "for blank unit" do
      it "allows blank display_name and plural_name" do
        unit = build(:unit, name: "x", display_name: "", plural_name: "", category: "count")
        expect(unit).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:recipe_ingredients).dependent(:restrict_with_error) }
  end

  describe "#to_ml" do
    it "converts amount to milliliters using ml_ratio" do
      unit = build(:unit, ml_ratio: 10.0)
      expect(unit.to_ml(5)).to eq(50.0)
    end

    it "returns nil when ml_ratio is not present" do
      unit = build(:unit, category: "count", ml_ratio: nil)
      expect(unit.to_ml(5)).to be_nil
    end
  end

  describe "#from_ml" do
    it "converts milliliters to unit amount" do
      unit = build(:unit, ml_ratio: 10.0)
      expect(unit.from_ml(50.0)).to eq(5.0)
    end

    it "returns nil when ml_ratio is not present" do
      unit = build(:unit, category: "count", ml_ratio: nil)
      expect(unit.from_ml(50.0)).to be_nil
    end
  end

  describe "#display_name_for" do
    it "returns singular form for amount 1" do
      unit = build(:unit, display_name: "Scheibe", plural_name: "Scheiben")
      expect(unit.display_name_for(1)).to eq("Scheibe")
    end

    it "returns plural form for amount != 1" do
      unit = build(:unit, display_name: "Scheibe", plural_name: "Scheiben")
      expect(unit.display_name_for(2)).to eq("Scheiben")
    end

    it "returns display_name when plural_name is blank" do
      unit = build(:unit, display_name: "cl", plural_name: "cl")
      expect(unit.display_name_for(5)).to eq("cl")
    end
  end
end
