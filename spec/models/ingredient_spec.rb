require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe "Associations" do
    it { should have_many(:collection_ingredients).dependent(:destroy) }
    it { should have_many(:ingredient_collections).through(:collection_ingredients) }
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:recipes).through(:recipe_ingredients) }
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_numericality_of(:alcoholic_content).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
  end
end
