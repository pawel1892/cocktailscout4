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

  describe "scopes" do
    let!(:used_unit) { create(:unit, name: "used_cl") }
    let!(:unused_unit) { create(:unit, name: "unused_ml") }
    let!(:ingredient) { create(:ingredient) }
    let!(:recipe) { create(:recipe) }

    before do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: used_unit)
    end

    describe ".used" do
      it "returns units that are used in recipe ingredients" do
        expect(Unit.used).to include(used_unit)
        expect(Unit.used).not_to include(unused_unit)
      end
    end

    describe ".unused" do
      it "returns units that are not used in any recipe ingredients" do
        expect(Unit.unused).to include(unused_unit)
        expect(Unit.unused).not_to include(used_unit)
      end
    end

    describe ".by_category" do
      let!(:volume_unit) { create(:unit, :volume_unit) }
      let!(:count_unit) { create(:unit, :count_unit) }

      it "filters units by category" do
        expect(Unit.by_category("volume")).to include(volume_unit)
        expect(Unit.by_category("volume")).not_to include(count_unit)
      end

      it "returns all units when category is blank" do
        expect(Unit.by_category(nil).count).to eq(Unit.count)
        expect(Unit.by_category("").count).to eq(Unit.count)
      end
    end

    describe ".volume_units" do
      let!(:volume_unit) { create(:unit, :volume_unit) }
      let!(:count_unit) { create(:unit, :count_unit) }

      it "returns only volume units" do
        expect(Unit.volume_units).to include(volume_unit)
        expect(Unit.volume_units).not_to include(count_unit)
      end
    end

    describe ".count_units" do
      let!(:volume_unit) { create(:unit, :volume_unit) }
      let!(:count_unit) { create(:unit, :count_unit) }

      it "returns only count units" do
        expect(Unit.count_units).to include(count_unit)
        expect(Unit.count_units).not_to include(volume_unit)
      end
    end

    describe ".special_units" do
      let!(:special_unit) { create(:unit, :special_unit) }
      let!(:volume_unit) { create(:unit, :volume_unit) }

      it "returns only special units" do
        expect(Unit.special_units).to include(special_unit)
        expect(Unit.special_units).not_to include(volume_unit)
      end
    end
  end

  describe "#in_use?" do
    let(:unit) { create(:unit) }
    let(:ingredient) { create(:ingredient) }
    let(:recipe) { create(:recipe) }

    context "when unit is used in recipe ingredients" do
      before do
        create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit)
      end

      it "returns true" do
        expect(unit.in_use?).to be true
      end
    end

    context "when unit is not used" do
      it "returns false" do
        expect(unit.in_use?).to be false
      end
    end
  end

  describe "#can_delete?" do
    let(:unit) { create(:unit) }
    let(:ingredient) { create(:ingredient) }
    let(:recipe) { create(:recipe) }

    context "when unit is used in recipe ingredients" do
      before do
        create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit)
      end

      it "returns false" do
        expect(unit.can_delete?).to be false
      end
    end

    context "when unit is not used" do
      it "returns true" do
        expect(unit.can_delete?).to be true
      end
    end
  end

  describe "#recipe_ingredients_count" do
    let(:unit) { create(:unit) }
    let(:ingredient) { create(:ingredient) }
    let(:recipe) { create(:recipe) }

    it "returns the count of recipe ingredients using this unit" do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit)
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit)

      expect(unit.recipe_ingredients_count).to eq(2)
    end

    it "returns 0 when no recipe ingredients use this unit" do
      expect(unit.recipe_ingredients_count).to eq(0)
    end
  end

  describe "#destroy" do
    let(:unit) { create(:unit) }
    let(:ingredient) { create(:ingredient) }
    let(:recipe) { create(:recipe) }

    context "when unit is used in recipe ingredients" do
      before do
        create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit)
      end

      it "does not destroy the unit" do
        expect { unit.destroy }.not_to change(Unit, :count)
      end

      it "adds an error message" do
        unit.destroy
        expect(unit.errors[:base]).to include(/Einheit kann nicht gelöscht werden/)
      end

      it "returns false" do
        expect(unit.destroy).to be false
      end
    end

    context "when unit is not used" do
      it "destroys the unit" do
        unit # ensure unit is created before counting
        expect { unit.destroy }.to change(Unit, :count).by(-1)
      end

      it "returns the unit" do
        result = unit.destroy
        expect(result).to be_a(Unit)
        expect(result).to be_destroyed
      end
    end
  end
end
