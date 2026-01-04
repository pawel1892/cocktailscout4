FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    amount { 4.0 }
    unit { "cl" }
    position { 1 }
  end
end
