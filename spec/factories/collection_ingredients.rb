FactoryBot.define do
  factory :collection_ingredient do
    association :ingredient_collection
    association :ingredient
  end
end
