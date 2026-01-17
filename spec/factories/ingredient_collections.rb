FactoryBot.define do
  factory :ingredient_collection do
    association :user
    sequence(:name) { |n| "Collection #{n}" }
    notes { nil }
    is_default { false }

    trait :with_notes do
      notes { "Shopping list: rum, vodka, gin" }
    end

    trait :default do
      is_default { true }
    end

    trait :with_ingredients do
      transient do
        ingredients_count { 3 }
      end

      after(:create) do |collection, evaluator|
        create_list(:ingredient, evaluator.ingredients_count).each do |ingredient|
          collection.ingredients << ingredient
        end
      end
    end
  end
end
