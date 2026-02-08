FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    unit { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }
    amount { 4.0 }
    position { 1 }
  end
end
