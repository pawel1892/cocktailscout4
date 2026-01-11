require 'rails_helper'

RSpec.describe Recipe, type: :model do
  include_examples "visitable"

  describe "Associations" do
    it { should belong_to(:user) }
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:ingredients).through(:recipe_ingredients) }
    it { should have_many(:recipe_comments).dependent(:destroy) }
    it { should have_many(:recipe_images).dependent(:destroy) }
    it { should have_many(:ratings).dependent(:destroy) }
  end

  describe "Validations" do
    subject { build(:recipe) }
    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:slug).case_insensitive }
  end
end
