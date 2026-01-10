FactoryBot.define do
  factory :recipe_comment do
    association :user
    association :recipe
    body { "This is a tasty cocktail!" }
    old_id { nil }
  end
end