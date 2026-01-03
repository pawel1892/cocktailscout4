require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).case_insensitive }
  it { should validate_numericality_of(:alcoholic_content).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
end
