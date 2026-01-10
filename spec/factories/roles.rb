FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }

    # Ensures that if we ask for 'admin' twice, we get the same DB record
    # instead of crashing with a uniqueness error.
    initialize_with { Role.find_or_create_by(name: name) }

    trait :admin do
      name { "admin" }
    end

    trait :forum_moderator do
      name { "forum_moderator" }
    end

    trait :recipe_moderator do
      name { "recipe_moderator" }
    end

    trait :image_moderator do
      name { "image_moderator" }
    end
  end
end
