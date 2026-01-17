FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "My Cocktail #{n}" }
    sequence(:slug) { |n| "my-cocktail-#{n}" }
    description { "A delicious cocktail" }
    association :user
    alcohol_content { 15.5 }
    total_volume { 20.0 }

    trait :with_ingredients do
      transient do
        ingredients_count { 2 }
      end

      after(:create) do |recipe, evaluator|
        create_list(:recipe_ingredient, evaluator.ingredients_count, recipe: recipe)
      end
    end
  end
end
