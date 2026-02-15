FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "Ingredient #{n}" }
    alcoholic_content { 0.0 }

    trait :alcoholic do
      alcoholic_content { 40.0 }
    end

    trait :with_ml_per_unit do
      ml_per_unit { 30.0 }
    end
  end
end
