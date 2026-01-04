# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_profile do
    user { FactoryGirl.build :user }
    prename { Faker::Name.first_name }
    public_mail { Faker::Internet.email }
    homepage { Faker::Internet.url }
    location { Faker::Address.city }
  end
end