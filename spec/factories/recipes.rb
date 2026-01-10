FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "My Cocktail #{n}" }
    sequence(:slug) { |n| "my-cocktail-#{n}" }
    description { "A delicious cocktail" }
    association :user
    alcohol_content { 15.5 }
    total_volume { 20.0 }
  end
end
