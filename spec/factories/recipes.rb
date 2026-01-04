FactoryBot.define do
  factory :recipe do
    title { "My Cocktail" }
    slug { "my-cocktail" }
    description { "A delicious cocktail" }
    association :user
    alcohol_content { 15.5 }
    total_volume { 20.0 }
  end
end
