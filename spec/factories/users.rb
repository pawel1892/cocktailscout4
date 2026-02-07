FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      after(:create) do |user|
        user.roles << create(:role, :admin)
      end
    end

    trait :forum_moderator do
      after(:create) do |user|
        user.roles << create(:role, :forum_moderator)
      end
    end

    trait :recipe_moderator do
      after(:create) do |user|
        user.roles << create(:role, :recipe_moderator)
      end
    end

    trait :image_moderator do
      after(:create) do |user|
        user.roles << create(:role, :image_moderator)
      end
    end

    trait :super_moderator do
      after(:create) do |user|
        user.roles << create(:role, :super_moderator)
      end
    end
  end
end
