# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_ingredient do
    user_id 1
    ingredient_id 1
    dimension "MyString"
  end
end
