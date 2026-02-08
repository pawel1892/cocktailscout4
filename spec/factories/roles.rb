FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }

    # Ensures that if we ask for 'admin' twice, we get the same DB record
    # instead of crashing with a uniqueness error.
    initialize_with { Role.find_or_create_by(name: name) }

    trait :admin do
      name { "admin" }
      display_name { "Admin" }
    end

    trait :forum_moderator do
      name { "forum_moderator" }
      display_name { "Forum-Moderator" }
    end

    trait :recipe_moderator do
      name { "recipe_moderator" }
      display_name { "Rezept-Moderator" }
    end

    trait :image_moderator do
      name { "image_moderator" }
      display_name { "Bild-Moderator" }
    end

    trait :super_moderator do
      name { "super_moderator" }
      display_name { "Moderator" }
    end
  end
end
