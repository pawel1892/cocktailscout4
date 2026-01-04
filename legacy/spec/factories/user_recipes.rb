# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_recipe do
    recipe_id 1
    user_id ""
    list "MyString"
  end
end
