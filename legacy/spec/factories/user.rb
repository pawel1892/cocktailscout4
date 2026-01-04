FactoryGirl.define do
  factory :user do
    login { Faker::Internet.user_name }
    password '123456'
    email { Faker::Internet.email }
    confirmed_at { Date.today - 1.year }

    factory :admin_user do |user|
      after(:create) {|user| user.add_role(:admin)}
    end

    factory :forum_moderator_user do |user|
      after(:create) {|user| user.add_role(:forum_moderator)}
    end

    trait :with_recipes do
      after(:create) {|user| user.recipes << create(:recipe)}
    end

  end
end