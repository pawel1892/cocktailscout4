FactoryGirl.define do
  factory :recipe do |r|
    r.user { FactoryGirl.build :user }
    r.name 'TGV'
    r.description 'Mischen und trinken'
    r.recipe_ingredients {
      [FactoryGirl.create(:recipe_ingredient, ingredient: FactoryGirl.create(:ingredient)),
       FactoryGirl.create(:recipe_ingredient, ingredient: FactoryGirl.create(:ingredient))]
    }

    trait :non_alcoholic do
      after(:create) do |r|
        r.recipe_ingredients.each do |ri|
          ri.ingredient.alcoholic_content = 0
          ri.ingredient.save
        end
      end
    end
  end
end
