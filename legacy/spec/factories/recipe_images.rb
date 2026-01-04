# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :recipe_image do
    association :recipe
    association :user
    is_approved false
    approved_by 1
  end
end
