FactoryBot.define do
  factory :recipe_image do
    association :recipe
    association :user
    state { "pending" }
    old_id { nil }

    trait :with_image do
      after(:build) do |recipe_image|
        file = Rack::Test::UploadedFile.new(
          Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'),
          'image/jpeg'
        )
        recipe_image.image.attach(file)
      end
    end

    trait :approved do
      state { "approved" }
      moderated_at { Time.current }
      association :moderated_by, factory: :user
    end

    trait :rejected do
      state { "rejected" }
      moderated_at { Time.current }
      association :moderated_by, factory: :user
      moderation_reason { "Inhalt nicht geeignet" }
    end

    trait :pending do
      state { "pending" }
    end
  end
end
