FactoryBot.define do
  factory :unit do
    name { "cl" }
    display_name { "cl" }
    plural_name { "cl" }
    category { "volume" }
    ml_ratio { 10.0 }
    divisible { true }

    trait :ml do
      name { "ml" }
      display_name { "ml" }
      plural_name { "ml" }
      ml_ratio { 1.0 }
    end

    trait :tl do
      name { "tl" }
      display_name { "TL" }
      plural_name { "TL" }
      ml_ratio { 5.0 }
    end

    trait :spritzer do
      name { "spritzer" }
      display_name { "Spritzer" }
      plural_name { "Spritzer" }
      category { "special" }
      ml_ratio { 0.9 }
      divisible { false }
    end
  end
end
